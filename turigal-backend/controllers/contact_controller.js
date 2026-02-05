// controllers/contact_controller.js

const nodemailer = require('nodemailer');

// 1. Configuración del Transporte (SMTP)
// NOTA: En producción, usa variables de entorno: process.env.SMTP_USER, etc.
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com', // Ejemplo común
    port: 587,
    secure: false, // true para puerto 465, false para otros
    auth: {
        user: process.env.SMTP_USER || 'tu_correo@ejemplo.com', 
        pass: process.env.SMTP_PASS || 'tu_contraseña_app'
    },
});

/**
 * Endpoint: POST /api/contact
 * Envía un correo electrónico con los datos del formulario.
 */
const submitContact = async (req, res) => {
    const { name, email, phone, message } = req.body;

    // Validación básica
    if (!name || !email || !message) {
        return res.status(400).json({ message: "Faltan datos obligatorios." });
    }

    try {
        // 2. Definir el contenido del correo
        const mailOptions = {
            from: `"Formulario App" <${email}>`, // Quien envía (el usuario)
            to: process.env.ADMIN_EMAIL || 'info@turisgal.com', // Destino (el dueño)
            subject: `Nueva Consulta de: ${name}`,
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px;">
                    <h2 style="color: #0056b3;">Nueva Consulta desde la App</h2>
                    <hr>
                    <p><strong>Nombre:</strong> ${name}</p>
                    <p><strong>Email:</strong> ${email}</p>
                    <p><strong>Teléfono:</strong> ${phone || 'No indicado'}</p>
                    <br>
                    <p><strong>Mensaje:</strong></p>
                    <blockquote style="background: #f9f9f9; padding: 15px; border-left: 5px solid #0056b3;">
                        ${message}
                    </blockquote>
                    <hr>
                    <small style="color: grey;">Enviado desde Turisgal App</small>
                </div>
            `,
        };

        // 3. Enviar el correo
        // Si no tienes credenciales reales configuradas, esto fallará, 
        // así que envolvemos en try/catch para que la App no se cuelgue.
        if (process.env.SMTP_USER) {
            const info = await transporter.sendMail(mailOptions);
            console.log(`[CONTACTO] Correo enviado: ${info.messageId}`);
        } else {
            console.log(`[CONTACTO SIMULADO] Email recibido de ${name}. (Falta configurar SMTP)`);
        }

        // 4. Responder a Flutter
        return res.status(200).json({ 
            success: true, 
            message: "Mensaje recibido correctamente. Nos pondremos en contacto pronto." 
        });

    } catch (error) {
        console.error("Error enviando email:", error);
        // Devolvemos 500 pero con un mensaje amable, o 200 si queremos simular éxito en desarrollo
        return res.status(500).json({ 
            message: "Error al enviar el correo. Inténtalo más tarde." 
        });
    }
};

module.exports = { submitContact };