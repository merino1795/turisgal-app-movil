require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// --- IMPORTAR RUTAS ---
const authRoutes = require('./routes/auth.routes');
const passwordRoutes = require('./routes/password.routes');
const checkinRoutes = require('./routes/checkin.routes');
const checkoutRoutes = require('./routes/checkout.routes');
const chatRoutes = require('./routes/chat.routes');
// ASEGÚRATE DE QUE ESTE NOMBRE DE ARCHIVO ES EXACTO EN TU CARPETA ROUTES
const reservationRoutes = require('./routes/reservation.routes'); 
const reviewRoutes = require('./routes/review.routes');
const contactRoutes = require('./routes/contact.routes');
const publicRoutes = require('./routes/public.routes');

// --- IMPORTAR MIDDLEWARE ---
const authenticateToken = require('./middleware/auth_middleware');

// --- CONFIGURACIÓN ---
const app = express();
const port = process.env.PORT || 3000;
const saltRounds = 10;

// =================================================================
// 1. FUNCIÓN: ASEGURAR USUARIO DE PRUEBA
// =================================================================
async function ensureTestUser() {
    const testEmail = 'test@turigal.com';
    const testPassword = 'Password123!'; 
    const testPhone = '600123456'; 

    try {
        let user = await prisma.user.findUnique({ where: { email: testEmail } });

        if (!user) {
            console.log("Creating test user...");
            const hashedPassword = await bcrypt.hash(testPassword, saltRounds);
            
            user = await prisma.user.create({
                data: {
                    email: testEmail,
                    password: hashedPassword,
                    nombre: 'Test',
                    apellido: 'User',
                    telefono: testPhone
                }
            });
            console.log(`Usuario de prueba creado: ${testEmail}`);
        } else {
            console.log(`Usuario de prueba existente: ${testEmail}`);
        }
        return user;
    } catch (e) {
        console.error('Error asegurando usuario de prueba:', e.message);
    }
}

// =================================================================
// 2. CONFIGURACIÓN DE LA APP
// =================================================================
function setupApp() {
    app.use(express.json({ limit: '50mb' }));
    app.use(express.urlencoded({ limit: '50mb', extended: true }));
    app.use(cors());

    app.use((req, res, next) => {
        console.log(`📡 [PETICIÓN ENTRANTE] ${req.method.toUpperCase()} ${req.url}`);
        next();
    });
    
    app.get('/', (req, res) => {
        res.status(200).send('Turisgal Backend API is Running! 🚀');
    });

    // --- MONTAJE DE RUTAS ---
    app.use('/api/auth', authRoutes);
    app.use('/api/password', passwordRoutes);
    app.use('/api/public', publicRoutes);
    app.use('/api/contact', contactRoutes);
    app.use('/api/checkin', checkinRoutes);

    // Rutas Protegidas
    app.use('/api/checkout', checkoutRoutes);
    app.use('/api/chat', chatRoutes);
    
    console.log("🔌 Conectando rutas de reservas...");
    app.use('/api/reservations', reservationRoutes);
    
    app.use('/api/reviews', reviewRoutes);

    app.get('/api/profile', authenticateToken, async (req, res) => {
        try {
            const user = await prisma.user.findUnique({
                where: { id: req.user.id },
                select: { id: true, email: true, nombre: true, telefono: true }
            });
            res.json(user);
        } catch (e) {
            res.status(500).json({ error: 'Error fetching profile' });
        }
    });

    // 404
    app.use((req, res) => {
        res.status(404).json({ message: `Ruta no encontrada: ${req.originalUrl}` });
    });
}

// =================================================================
// 3. INICIO DEL SERVIDOR
// =================================================================
async function startServer() {
    try {
        await prisma.$connect();
        console.log("Conexión a Base de Datos: OK");
        await ensureTestUser();
        setupApp();

        app.listen(port, '0.0.0.0', () => {
            console.log(`\n========================================`);
            console.log(`SERVIDOR LISTO EN: http://localhost:${port}`);
            console.log(`========================================`);
            
            // IMPRIMIR EL MAPA REAL DE RUTAS
            console.log("\nMAPA DE RUTAS CARGADAS:");
            printRoutes(app);
            console.log("========================================\n");
        });

    } catch (e) {
        console.error("Fallo crítico al iniciar:", e);
        process.exit(1);
    }
}

// --- HERRAMIENTA DE DIAGNÓSTICO ---
function printRoutes(app) {
    app._router.stack.forEach((middleware) => {
        if (middleware.route) { // Rutas directas
            console.log(`   GET  ${middleware.route.path}`);
        } else if (middleware.name === 'router') { // Grupos (Router)
            const regex = middleware.regexp.toString();
            const basePath = regex.replace('\\/?(?=\\/|$)', '').replace('/^\\', '').replace('\\/?(?=\\/|$)/i', '').replace(/\\\//g, '/');
            
            middleware.handle.stack.forEach((handler) => {
                if (handler.route) {
                    const method = Object.keys(handler.route.methods)[0].toUpperCase();
                    let path = handler.route.path;
                    const fullPath = (basePath + path).replace('//', '/');
                    console.log(`   ${method.padEnd(4)} ${fullPath}`);
                }
            });
        }
    });
}

startServer();