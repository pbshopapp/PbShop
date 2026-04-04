import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"
import { JWT } from "npm:google-auth-library@8.8.0"

serve(async (req) => {
  console.log("!!! FUNCIÓN INVOCADA - PB-SHOP !!!");
  try {
    const payload = await req.json()
    const { record, type } = payload
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    let tokensDestino: string[] = []
    let titulo = ""
    let cuerpo = ""
    let dataExtra = {} // <--- 1. INICIALIZAR VACÍO FUERA DE LOS IF

    if (type === 'INSERT') {
      titulo = "¡Nuevo pedido en PB-Shop! 🍔"
      cuerpo = "Tienes un pedido pendiente por preparar."
      
// En tu index.ts de Supabase, cuando el estado sea 'LISTO'
      dataExtra = { 
        screen: "TENDERO", 
        id_pedido: record.id.toString(),
        tipo_alerta: "NORMAL" // <--- Agregamos este campo
      };
      
      const { data: tendero } = await supabase
        .from('perfiles')
        .select('id')
        .eq('rol', 'tendero')
        .maybeSingle()
      
      if (tendero) {
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
      
      dataExtra = { 
        screen: "ESTUDIANTE",
        id_pedido: record.id.toString(),
        // Si el estado es 'LISTO', mandamos URGENTE, si no, NORMAL
        tipo_alerta: record.estado === 'listo' ? "URGENTE" : "NORMAL" 
      };

      const { data: rows } = await supabase
        .from('fcm_tokens')
        .select('token')
        .eq('usuario_id', record.id_usuario)
      
      if (rows) tokensDestino = rows.map(r => r.token)
    }

    if (tokensDestino.length > 0) {
      console.log(`Enviando a ${tokensDestino.length} dispositivos...`)
      console.log("--- DEBUG ENVIANDO NOTIFICACIÓN ---");
      console.log("Estado del pedido:", record.estado);
      console.log("Data que se enviará:", JSON.stringify(dataExtra));
      const promesas = tokensDestino.map(token => 
        enviarAFirebase(token, titulo, cuerpo, dataExtra) // <--- 2. PASAR dataExtra AQUÍ
      )
      
      const resultados = await Promise.all(promesas)
      return new Response(JSON.stringify(resultados), { status: 200 })
    }

    return new Response(JSON.stringify({ message: "Sin tokens" }), { status: 200 })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

// 3. ACTUALIZAR LA FUNCIÓN PARA RECIBIR Y ENVIAR EL DATA
async function enviarAFirebase(fcmToken: string, title: string, body: string, dataExtra: any) {
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
            channel_id: "pbshop_canal_final",
            sound: "noti",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            notification_priority: "PRIORITY_MAX",
          }
        },
        data: { 
          //title: title, // Mandamos el título como dato
          //body: body,   // Mandamos el cuerpo como dato
          ...dataExtra, // <--- AQUÍ SE INCLUYEN screen E id_pedido
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        }, 
      },
    }),
  })

  return await res.json()
}