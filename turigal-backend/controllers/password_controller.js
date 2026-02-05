// controllers/password_controller.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcryptjs'); // Para encriptar la nueva contraseña

/**
 * -------------------------------------------------------
 * 1. SOLICITAR RESETEO (Generar PIN)
 * -------------------------------------------------------
 * Endpoint: POST /api/password/request-reset
 * Flutter envía: { email, phone }
 */
const requestReset = async (req, res) => {
    const { email, phone } = req.body;

    if (!email) return res.status(400).json({ message: "El email es obligatorio." });

    try {
        // 1. Verificar que el usuario existe
        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) {
            // Por seguridad, no decimos "usuario no existe", decimos "si existe, se envió"
            // Pero para tu desarrollo, devolvemos 404 para que sepas qué pasa.
            return res.status(404).json({ message: "Usuario no encontrado." });
        }

        // 2. Generar un PIN de 6 dígitos
        const pin = Math.floor(100000 + Math.random() * 900000).toString();

        // 3. Guardar el PIN en la base de datos (con fecha de expiración)
        // Necesitas un modelo 'PasswordReset' en tu schema.prisma o campos en 'User'
        // Aquí asumimos que actualizamos campos en el usuario para simplificar.
        await prisma.user.update({
            where: { email },
            data: {
                resetToken: pin, // Guardamos el PIN
                resetTokenExpires: new Date(Date.now() + 15 * 60 * 1000) // Expira en 15 mins
            }
        });

        // 4. (Simulación) Enviar Email/SMS
        console.log(`[EMAIL SERVICE] Enviando PIN ${pin} a ${email}`);

        // 5. Responder a Flutter
        // EN PRODUCCIÓN: No devuelvas el PIN aquí.
        // EN DESARROLLO: Lo devolvemos para que puedas probar la App sin configurar emails reales.
        return res.status(200).json({ 
            message: "PIN enviado.", 
            debugToken: pin // <-- Úsalo en la pantalla de Flutter
        });

    } catch (error) {
        console.error("Error solicitando reset:", error);
        return res.status(500).json({ message: "Error interno." });
    }
};

/**
 * -------------------------------------------------------
 * 2. VERIFICAR PIN
 * -------------------------------------------------------
 * Endpoint: POST /api/password/verify-token
 * Flutter envía: { email, token }
 */
const verifyToken = async (req, res) => {
    const { email, token } = req.body;

    try {
        const user = await prisma.user.findUnique({ where: { email } });

        if (!user) return res.status(404).json({ message: "Usuario no encontrado." });

        // Verificar coincidencia y expiración
        if (user.resetToken !== token) {
            return res.status(400).json({ message: "PIN incorrecto." });
        }

        if (new Date() > new Date(user.resetTokenExpires)) {
            return res.status(400).json({ message: "El PIN ha expirado." });
        }

        // Si es correcto, generamos una "llave de cambio" temporal
        // Esto evita que alguien cambie la contraseña solo sabiendo el PIN anterior
        const resetKey = `KEY-${Math.random().toString(36).substr(2, 9)}`;
        
        // La guardamos para el siguiente paso
        // (Podrías reutilizar el campo resetToken, pero es mejor separar conceptos)
        await prisma.user.update({
            where: { email },
            data: { resetToken: resetKey } // Reemplazamos el PIN por la Key
        });

        return res.status(200).json({ 
            message: "PIN verificado.", 
            resetKey: resetKey // Flutter guarda esto en memoria
        });

    } catch (error) {
        console.error("Error verificando token:", error);
        return res.status(500).json({ message: "Error interno." });
    }
};

/**
 * -------------------------------------------------------
 * 3. ACTUALIZAR CONTRASEÑA
 * -------------------------------------------------------
 * Endpoint: POST /api/password/update
 * Flutter envía: { email, resetKey, newPassword }
 */
const updatePassword = async (req, res) => {
    const { email, resetKey, newPassword } = req.body;

    if (!newPassword || newPassword.length < 8) {
        return res.status(400).json({ message: "La contraseña es muy corta." });
    }

    try {
        const user = await prisma.user.findUnique({ where: { email } });

        // Verificar que tienen la llave correcta (seguridad)
        if (!user || user.resetToken !== resetKey) {
            return res.status(403).json({ message: "Sesión de reseteo inválida o expirada." });
        }

        // Encriptar nueva contraseña
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        // Actualizar en BD y limpiar tokens
        await prisma.user.update({
            where: { email },
            data: {
                password: hashedPassword,
                resetToken: null,
                resetTokenExpires: null
            }
        });

        return res.status(200).json({ message: "Contraseña actualizada con éxito." });

    } catch (error) {
        console.error("Error actualizando password:", error);
        return res.status(500).json({ message: "Error interno." });
    }
};

module.exports = { requestReset, verifyToken, updatePassword };