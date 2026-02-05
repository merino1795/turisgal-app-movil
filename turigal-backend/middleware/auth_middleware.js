
const jwt = require('jsonwebtoken'); // Librería para verificar tokens

// Clave secreta (Debe coincidir EXACTAMENTE con la de auth_controller.js)
const JWT_SECRET = process.env.JWT_SECRET || 'turisgal_secret_key_123';

/**
 * Middleware de Autenticación
 * ---------------------------
 * Intercepta la petición antes de que llegue al controlador.
 * 1. Busca la cabecera 'Authorization'.
 * 2. Extrae el token "Bearer".
 * 3. Verifica que sea válido y no haya expirado.
 * 4. Inyecta los datos del usuario en 'req.user' para que el controlador los use.
 */
const authenticateToken = (req, res, next) => {
    // 1. Obtener la cabecera de autorización
    // El formato estándar es: "Authorization: Bearer <TOKEN_AQUI>"
    const authHeader = req.headers['authorization'];
    
    // Si existe la cabecera, dividimos el string por el espacio y cogemos la segunda parte (el token)
    // Si no existe, token será undefined.
    const token = authHeader && authHeader.split(' ')[1];

    // 2. Si no hay token, denegamos el acceso inmediatamente (401 Unauthorized)
    if (!token) {
        return res.status(401).json({ 
            message: 'Acceso denegado. Se requiere autenticación.' 
        });
    }

    // 3. Verificar el token
    jwt.verify(token, JWT_SECRET, (err, decodedUser) => {
        if (err) {
            // Si hay error (token expirado, firma falsa, modificado), devolvemos 403 Forbidden
            console.error("Error verificando token:", err.message);
            return res.status(403).json({ 
                message: 'Token inválido o expirado. Por favor, inicie sesión de nuevo.' 
            });
        }

        // 4. Token válido: Inyectamos los datos en la petición
        // En auth_controller.js guardamos: { id, email }
        // Ahora cualquier controlador siguiente puede usar: req.user.id
        req.user = decodedUser;

        // 5. Continuar con la siguiente función (el controlador real)
        next();
    });
};

module.exports = authenticateToken; // Exportamos la función