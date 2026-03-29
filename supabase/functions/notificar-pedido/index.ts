import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"
import { JWT } from "npm:google-auth-library@8.8.0"

serve(async (req) => {
  try {
    const payload = await req.json()
    const { record, old_record, type } = payload
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    let tokensDestino: string[] = []
    let titulo = ""
    let cuerpo = ""

    // 1. LÓGICA PARA NUEVO PEDIDO (Para el tendero)
    if (type === 'INSERT') {
      titulo = "¡Nuevo pedido en PB-Shop! 🍔"
      cuerpo = `Tienes un nuevo pedido pendiente. ¡A trabajar!`
      
      // Buscamos todos los tokens de los usuarios con rol 'tendero'
      const { data: tenderos } = await supabase
        .from('perfiles')
        .select('id')
        .eq('rol', 'tendero')

      if (tenderos && tenderos.length > 0) {
        const idsTenderos = tenderos.map(t => t.id)
        const { data: fcmRows } = await supabase
          .from('fcm_tokens')
          .select('token')
          .in('usuario_id', idsTenderos)
        
        tokensDestino = fcmRows?.map(r => r.token) || []
      }
    } 
    // 2. LÓGICA PARA ACTUALIZACIÓN (Para el cliente)
    else if (type === 'UPDATE' && record.estado !== old_record.estado) {
      titulo = "Actualización de tu pedido"
      cuerpo = `Tu pedido ahora está: ${record.estado}`
      
      // Traemos todos los tokens registrados para ese usuario específico
      const { data: fcmRows } = await supabase
        .from('fcm_tokens')
        .select('token')
        .eq('usuario_id', record.id_usuario)
      
      tokensDestino = fcmRows?.map(r => r.token) || []
    }

    // 3. ENVÍO MULTI-DISPOSITIVO
    if (tokensDestino.length > 0) {
      console.log(`Enviando a ${tokensDestino.length} dispositivos...`)
      
      // Ejecutamos todos los envíos en paralelo
      const promesas = tokensDestino.map(token => 
        enviarAFirebase(token, titulo, cuerpo, record.id)
      )
      
      const resultados = await Promise.all(promesas)
      return new Response(JSON.stringify({ total: resultados.length, detalles: resultados }), { 
        status: 200, 
        headers: { "Content-Type": "application/json" } 
      })
    }

    return new Response(JSON.stringify({ message: "No se encontraron tokens activos" }), { status: 200 })

  } catch (error) {
    console.error("Error crítico:", error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

async function enviarAFirebase(fcmToken: string, title: string, body: string, idPedido: any) {
  const rawConfig = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!rawConfig) throw new Error("Falta FIREBASE_SERVICE_ACCOUNT")

  const firebaseConfig = JSON.parse(rawConfig.trim())
  const client = new JWT({
    email: firebaseConfig.client_email,
    key: firebaseConfig.private_key,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  })

  const { token } = await client.getAccessToken()
  const projectId = firebaseConfig.project_id

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        data: { 
          id_pedido: idPedido.toString(),
          click_action: "FLUTTER_NOTIFICATION_CLICK" 
        },
        android: {
          priority: "high",
          notification: {
            channel_id: "pbshop_canal_alto",
            sound: "default"
          }
        }
      }
    })
  })

  return await res.json()
}