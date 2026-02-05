const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcryptjs'); // Para encriptar contraseñas
const jwt = require('jsonwebtoken'); // Para generar el token de sesión

// Clave secreta para firmar los tokens (En producción, usar variable de entorno)
const JWT_SECRET = process.env.JWT_SECRET || 'turisgal_secret_key_123';

/**
 * -------------------------------------------------------
 * 1. REGISTRO DE USUARIO
 * -------------------------------------------------------
 * Endpoint: POST /api/auth/register
 * Recibe: { name, surname, email, phone, password } desde Flutter.
 */
const register = async (req, res) => {
    try {
        const { name, surname, email, phone, password } = req.body;

        // 1. Validaciones básicas
        if (!email || !password || !name) {
            return res.status(400).json({ message: "Faltan datos obligatorios." });
        }

        // 2. Comprobar si el usuario ya existe
        const existingUser = await prisma.user.findUnique({
            where: { email: email }
        });

        if (existingUser) {
            return res.status(409).json({ message: "El email ya está registrado." });
        }

        // 3. Encriptar la contraseña (Hash)
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 4. Crear el usuario en la Base de Datos
        // NOTA: Asegúrate de que los nombres de campos coinciden con tu schema.prisma
        // (nombre, apellido, telefono, email, password)
        const newUser = await prisma.user.create({
            data: {
                nombre: name,
                apellido: surname || "",
                email: email,
                telefono: phone || "",
                password: hashedPassword,
                createdAt: new Date(),
                updatedAt: new Date()
            }
        });

        // 5. Generar Token JWT para que el usuario quede logueado automáticamente
        const token = jwt.sign(
            { id: newUser.id, email: newUser.email },
            JWT_SECRET,
            { expiresIn: '30d' } // El token dura 30 días
        );

        // 6. Responder a Flutter (excluyendo la contraseña)
        const { password: _, ...userWithoutPassword } = newUser;

        return res.status(201).json({
            message: "Usuario registrado con éxito.",
            token: token,
            user: userWithoutPassword
        });

    } catch (error) {
        console.error("Error en registro:", error);
        return res.status(500).json({ message: "Error interno del servidor al registrar." });
    }
};

/**
 * -------------------------------------------------------
 * 2. LOGIN DE USUARIO
 * -------------------------------------------------------
 * Endpoint: POST /api/auth/login
 * Recibe: { email, password }
 */
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // 1. Validación
        if (!email || !password) {
            return res.status(400).json({ message: "Email y contraseña son obligatorios." });
        }

        // 2. Buscar usuario
        const user = await prisma.user.findUnique({
            where: { email: email }
        });

        if (!user) {
            return res.status(401).json({ message: "Credenciales inválidas." });
        }

        // 3. Comparar contraseña (Hash vs Texto plano)
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: "Credenciales inválidas." });
        }

        // 4. Generar Token
        const token = jwt.sign(
            { id: user.id, email: user.email },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        // 5. Responder
        const { password: _, ...userWithoutPassword } = user;

        return res.status(200).json({
            message: "Login exitoso.",
            token: token,
            user: userWithoutPassword
        });

    } catch (error) {
        console.error("Error en login:", error);
        return res.status(500).json({ message: "Error interno del servidor." });
    }
};

/**
 * -------------------------------------------------------
 * 3. OBTENER PERFIL (Datos frescos)
 * -------------------------------------------------------
 * Endpoint: GET /api/auth/profile
 * Requiere: Header 'Authorization: Bearer TOKEN'
 */
const getProfile = async (req, res) => {
    try {
        // req.user viene del middleware de autenticación (que decodifica el token)
        // Si no tienes middleware aún, req.user será undefined.
        const userId = req.user ? req.user.id : null;

        if (!userId) {
            return res.status(401).json({ message: "No autorizado." });
        }

        const user = await prisma.user.findUnique({
            where: { id: userId }
        });

        if (!user) {
            return res.status(404).json({ message: "Usuario no encontrado." });
        }

        const { password: _, ...userWithoutPassword } = user;

        return res.json(userWithoutPassword);

    } catch (error) {
        console.error("Error obteniendo perfil:", error);
        return res.status(500).json({ message: "Error del servidor." });
    }
};

module.exports = {
    register,
    login,
    getProfile
};