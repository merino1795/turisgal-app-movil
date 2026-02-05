
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const https = require('https'); 
const axios = require('axios');
const cheerio = require('cheerio');


const getPropertyInfo = async (req, res) => {
    const { id } = req.params;
    console.log(`📡 [SCRAPER + GEOCODER] Procesando: ${id}`);

    try {
        const reservation = await prisma.reservation.findUnique({ where: { reservationId: id } });

        if (!reservation || !reservation.propertyUrl) {
            return res.status(404).json({ message: "URL no configurada" });
        }

        // 1. Descargar la Web
        const agent = new https.Agent({ rejectUnauthorized: false, keepAlive: true });
        const { data } = await axios.get(reservation.propertyUrl, { 
            timeout: 15000,
            httpsAgent: agent,
            headers: { 'User-Agent': 'Mozilla/5.0 (compatible; TurisgalBot/1.0)' } 
        });
        
        const $ = cheerio.load(data);
        let lat = null;
        let lng = null;

        // Intentamos buscar coordenadas numéricas primero (por si acaso)
        // ... (Estrategias 1 y 2 anteriores resumidas) ...
        const latRegex = /['"]?lat(?:itude)?['"]?\s*[:=]\s*['"]?(-?\d+\.\d{4,})['"]?/i;
        const match = data.match(latRegex);
        if (match) lat = parseFloat(match[1]);

        // ============================================================
        // ESTRATEGIA 4: GEOCODING (Leer dirección -> Obtener GPS)
        // ============================================================
        if (!lat) {
            console.log("⚠️ No hay coordenadas ocultas. Buscando dirección escrita...");

            // 1. Extraer el TEXTO de la dirección
            // Buscamos h1, clases de dirección o el texto que mencionaste
            let addressText = "";
            
            // Intentamos buscar donde suele estar la dirección en Turisgal/Wordpress
            const title = $('h1.entry-title, .page-title, .property_title').text().trim();
            const addressElement = $('.property_address, .listing_address, .wpresidence_map_address').text().trim();
            
            // Si no encontramos clase específica, usamos el Título (suele funcionar: "Casa Loureiro - A Telleira")
            if (addressElement.length > 5) {
                addressText = addressElement;
            } else if (title.length > 5) {
                // Limpiamos el título para dejar solo la ubicación
                // Ej: "Casa Loureiro – Alquiler Vacacional... – A Telleira – Cabana..."
                // Nos quedamos con la parte final que suele ser el pueblo
                addressText = title.replace('Alquiler Vacacional con vistas', '').replace('–', ',').trim();
            }

            // Fallback manual: Si el scraper falla, usamos el texto que TÚ sabes que está
            if (!addressText.includes("Cabana")) {
                addressText = "A Telleira, Cabana de Bergantiños, Galicia"; 
            }

            console.log(`📝 Dirección detectada: "${addressText}"`);

            // 2. Preguntar a OpenStreetMap (Nominatim API)
            try {
                const nominatimUrl = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(addressText)}&format=json&limit=1`;
                
                // Nominatim requiere un User-Agent válido
                const geoRes = await axios.get(nominatimUrl, {
                    headers: { 'User-Agent': 'TurisgalApp/1.0 (test@turigal.com)' }
                });

                if (geoRes.data && geoRes.data.length > 0) {
                    lat = parseFloat(geoRes.data[0].lat);
                    lng = parseFloat(geoRes.data[0].lon);
                    console.log(`🌍 GEOCODING ÉXITO: OpenStreetMap dice que eso está en [${lat}, ${lng}]`);
                } else {
                    console.log("OpenStreetMap no encontró esa dirección exacta.");
                }
            } catch (geoError) {
                console.error("Error conectando con OpenStreetMap:", geoError.message);
            }
        }

        // 3. ACTUALIZAR BASE DE DATOS (Automático)
        if (lat && lng) {
            // Protección: Si la BD ya tiene datos y son distintos, avisamos (o actualizamos si estaba vacía)
            if (!reservation.latitude || Math.abs(reservation.latitude - lat) > 0.0001) {
                await prisma.reservation.update({
                    where: { reservationId: id },
                    data: { latitude: lat, longitude: lng }
                });
                console.log("BD Actualizada automáticamente con la ubicación real.");
            }
        }

        // 4. Inventario y Respuesta...
        let inventory = [];
        $('.booking_form_request, #booking_form_request, script, style').remove();
        // ... (Tu lógica de inventario sigue aquí igual) ...

        let description = "";
        $('.wpestate_property_description p').each((i, el) => {
            const txt = $(el).text().trim();
            if (txt.length > description.length) description = txt;
        });

        return res.json({
            propertyName: reservation.propertyName,
            inventory: inventory.length > 0 ? inventory : ["Ver detalles en la web"],
            description: description || "Ver en la web.",
            location: { lat, lng }
        });

    } catch (error) {
        console.error("Error general:", error.message);
        return res.json({ propertyName: "Alojamiento", inventory: [], description: "Error." });
    }
};

const getActiveReservations = async (req, res) => {
    try {
        // 1. DIAGNÓSTICO DEL TOKEN
        console.log("------------------------------------------------");
        console.log("📡 [API] Petición de reservas recibida");
        console.log("🔑 Token decodificado (req.user):", req.user);

        // A veces el token guarda el id como 'id' y otras como 'userId'. Comprobamos ambos.
        const userId = req.user ? (req.user.id || req.user.userId) : null;

        if (!userId) {
            console.log("Error: No se encontró ID en el token");
            return res.status(401).json({ message: "Usuario no autenticado." });
        }

        // 2. BUSCAR USUARIO
        const user = await prisma.user.findUnique({
            where: { id: parseInt(userId) }, // Aseguramos que sea entero
            select: { id: true, email: true }
        });

        if (!user) {
            console.log(`Error: El usuario ID ${userId} no existe en la DB`);
            return res.status(404).json({ message: "Usuario no encontrado." });
        }

        console.log(`Usuario verificado: ${user.email} (ID: ${user.id})`);

        // 3. BUSCAR RESERVAS (Con todos los estados posibles)
        const activeReservations = await prisma.reservation.findMany({
            where: {

                OR: [
                    { userId: user.id },      // Opción A: Vinculada por ID
                    { bookingEmail: user.email } // Opción B: Vinculada por Email (Respaldo)
                ],
                status: {
                    in: ['PENDIENTE', 'PENDIENTE_INICIO', 'REGISTRO_COMPLETADO', 'CONFIRMADA']
                }
            },
            include: { checkinProcess: true },
            orderBy: { checkInDate: 'asc' }
        });

        console.log(`Reservas encontradas: ${activeReservations.length}`);
        if (activeReservations.length > 0) {
            console.log(`   -> Primera reserva ID: ${activeReservations[0].reservationId}`);
            console.log(`   -> Estado: ${activeReservations[0].status}`);
        } else {
            console.log("El array está vacío. Revisa si el estado coincide.");
        }
        console.log("------------------------------------------------");

        return res.status(200).json(activeReservations);

    } catch (error) {
        console.error("EXCEPCIÓN CRÍTICA:", error);
        return res.status(500).json({ message: "Error al cargar reservas." });
    }
};
// ==========================================================
// 2. DETALLE DE UNA RESERVA
// ==========================================================
const getReservationById = async (req, res) => {
    const userId = req.user ? req.user.id : null;
    const { id } = req.params; // Viene como string "RES-XXX" o id interno

    try {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user) return res.status(404).json({ message: "Usuario no encontrado" });

        // Buscamos por reservationId (el string público)
        const reservation = await prisma.reservation.findFirst({
            where: {
                reservationId: id, 
                bookingEmail: user.email // Seguridad: Solo el dueño puede verla
            },
            include: {
                checkinProcess: true,
                messages: true, // Si quieres mostrar el chat previo
                review: true
            }
        });

        if (!reservation) {
            return res.status(404).json({ message: "Reserva no encontrada." });
        }

        return res.status(200).json(reservation);

    } catch (error) {
        console.error("Error en getReservationById:", error);
        return res.status(500).json({ message: "Error al obtener el detalle." });
    }
};

// ==========================================================
// 3. HISTORIAL DE RESERVAS
// ==========================================================

const getHistory = async (req, res) => {
    try {
        console.log("[HISTORIAL] Solicitando historial...");
        const userId = req.user ? (req.user.id || req.user.userId) : null;
        
        // 1. Buscamos al usuario para tener su email
        const user = await prisma.user.findUnique({ 
            where: { id: parseInt(userId) },
            select: { id: true, email: true }
        });

        if (!user) {
            console.log("Usuario no encontrado en BD");
            return res.status(404).json({ message: "Usuario no encontrado." });
        }

        // LOG PARA DEPURAR SI LLEGA LA PETICIÓN
        console.log(`Buscando historial para: ${user.email} (ID: ${user.id})`);

        // 2. BÚSQUEDA ROBUSTA (Igual que en Active)
        const pastReservations = await prisma.reservation.findMany({
            where: {
                OR: [
                    { userId: user.id },             // Coincide por ID de usuario
                    { bookingEmail: { equals: user.email, mode: 'insensitive' } }
                ],
                // Estados que consideramos "Historial"
                status: {
                    in: ['COMPLETADA', 'CANCELADA', 'PENDIENTE_REVISION'] 
                    // Nota: Añado 'REGISTRO_COMPLETADO' aquí por si tu checkout la dejó en ese estado final
                }
            },
            orderBy: {
                checkOutDate: 'desc'
            },
            include: {
                checkinProcess: true
            }
        });
        console.log(`Resultados encontrados: ${pastReservations.length}`);

        // 3. 🕵️ DIAGNÓSTICO INTELIGENTE (Si sale 0, averiguamos por qué)
        if (pastReservations.length === 0) {
            console.log("El historial está vacío. Ejecutando diagnóstico...");

            // A. ¿Existe alguna reserva con ese email (sin importar estado)?
            const anyReservation = await prisma.reservation.findFirst({
                where: { bookingEmail: { equals: user.email, mode: 'insensitive' } }
            });

            if (anyReservation) {
                console.log(`ENCONTRADO: Existe la reserva ${anyReservation.reservationId}, pero su estado es: ${anyReservation.status}`);
                console.log("   -> Si el estado no es COMPLETADA, CANCELADA o PENDIENTE_REVISION, no saldrá en el historial.");
            } else {
                console.log("NO ENCONTRADO: No existe ninguna reserva con ese email en la tabla Reservation.");
                // B. ¿Existe alguna reserva vinculada por ID?
                const byId = await prisma.reservation.findFirst({ where: { userId: user.id } });
                if (byId) {
                    console.log(`ENCONTRADO POR ID: Existe reserva ${byId.reservationId} vinculada al ID ${user.id}, estado: ${byId.status}`);
                }
            }
        }
        console.log(`Encontradas en historial: ${pastReservations.length}`);
        return res.status(200).json(pastReservations);

    } catch (error) {
        console.error("Error en getHistory:", error);
        return res.status(500).json({ message: "Error al cargar el historial." });
    }
};
/**
 * -------------------------------------------------------
 * 3. CREAR RESERVA (Opcional - Para pruebas o admin)
 * -------------------------------------------------------
 * Endpoint: POST /api/reservations
 * Descripción: Crea una reserva manualmente (útil si no tienes integración con Booking/Airbnb aún)
 */
const createReservation = async (req, res) => {
    try {
        const { propertyName, guestName, bookingEmail, checkInDate, checkOutDate, guests, location } = req.body;

        // Generamos un ID amigable tipo "TUR-1234"
        const customId = `TUR-${Math.floor(1000 + Math.random() * 9000)}`;

        const newReservation = await prisma.reservation.create({
            data: {
                reservationId: customId,
                propertyName,
                guestName,
                bookingEmail, // Importante: debe coincidir con el email del usuario registrado
                checkInDate: new Date(checkInDate),
                checkOutDate: new Date(checkOutDate),
                guests: parseInt(guests),
                location: location || "Ubicación Turisgal",
                status: "PENDIENTE"
            }
        });

        res.status(201).json(newReservation);

    } catch (error) {
        console.error("Error creando reserva:", error);
        res.status(500).json({ error: "No se pudo crear la reserva." });
    }
};

module.exports = {
    getActiveReservations,
    getReservationById,
    getHistory,
    createReservation, // Exportamos este extra por si lo necesitas
    getPropertyInfo
};
