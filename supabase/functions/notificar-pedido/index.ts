import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"
import { JWT } from "npm:google-auth-library@8.8.0"

serve(async (req) => {
  console.log("!!! FUNCIÓN INVOCADA - PB-SHOP !!!"); // <--- AGREGA ESTA LÍNEA
  try {
    const payload = await req.json()
    console.log("Payload recibido:", JSON.stringify(payload));
    const { record, old_record, type } = payload
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // <--- USA ESTA VARIABLE
      {
        auth: {
          persistSession: false,
        },
      }
    )

    // ... dentro del serve ...
    let tokensDestino: string[] = [] // Ahora es una lista de tokens
    let titulo = ""
    let cuerpo = ""

    if (type === 'INSERT') {
      titulo = "¡Nuevo pedido en PB-Shop! 🍔"
      cuerpo = "Tienes un pedido pendiente por preparar."
      
      // 1. Buscamos al tendero
      const { data: tendero } = await supabase
        .from('perfiles')
        .select('id')
        .eq('rol', 'tendero')
        .maybeSingle()

      if (tendero) {
        // 2. Traemos TODOS sus tokens de la tabla fcm_tokens
        const { data: rows } = await supabase
          .from('fcm_tokens')
          .select('token')
          .eq('usuario_id', tendero.id)
        
        if (rows) tokensDestino = rows.map(r => r.token)
      }
    } 
    else if (type === 'UPDATE') {
      titulo = "Actualización de pedido 📦"
      cuerpo = `Tu pedido de PB-Shop ahora está: ${record.estado}`
      
      // Traemos TODOS los tokens del estudiante que hizo el pedido
      const { data: rows } = await supabase
        .from('fcm_tokens')
        .select('token')
        .eq('usuario_id', record.id_usuario)
      
      if (rows) tokensDestino = rows.map(r => r.token)
    }

    // EJECUCIÓN PARA TODOS LOS TOKENS
    if (tokensDestino.length > 0) {
      console.log(`Enviando a ${tokensDestino.length} dispositivos...`)
      
      // Usamos Promise.all para enviar a todos en paralelo (más rápido)
      const promesas = tokensDestino.map(token => 
        enviarAFirebase(token, titulo, cuerpo, record.id)
      )
      
      const resultados = await Promise.all(promesas)
      console.log("Resultados de envíos:", JSON.stringify(resultados))
      
      return new Response(JSON.stringify({ sent: tokensDestino.length }), { status: 200 })
    } else {
      console.log("No se encontraron tokens para este envío.")
      return new Response(JSON.stringify({ message: "Sin tokens" }), { status: 200 })
    }

    return new Response(JSON.stringify({ message: "No se requería notificación" }), { status: 200 })

  } catch (error) {
    console.error("Error crítico:", error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

async function enviarAFirebase(fcmToken: string, title: string, body: string, idPedido: any) {
  const rawConfig = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!rawConfig) throw new Error("Secret no configurado.");

  const firebaseConfig = JSON.parse(rawConfig.trim());
  const client = new JWT({
    email: firebaseConfig.client_email,
    key: firebaseConfig.private_key,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });

  const { token } = await client.getAccessToken()
  const projectId = firebaseConfig.project_id

  // Formato de ALTA PRIORIDAD para asegurar el Pop-up
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
        android: {
          priority: "high",
          notification: {
            sound: "default",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            notification_priority: "PRIORITY_MAX", // Máxima importancia en Android
          }
        },
        data: { 
          id_pedido: idPedido.toString(),
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        }, 
      },
    }),
  })

  return await res.json()
}