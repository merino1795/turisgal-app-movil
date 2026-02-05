
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const Tesseract = require('tesseract.js'); 

/**
 * ------------------------------------------------------------------
 * 1. VALIDAR RESERVA (Paso 1 del Frontend)
 * ------------------------------------------------------------------
 */
const validateReservation = async (req, res) => {
    try {
        console.log("[CHECK-IN] Recibido código:", req.body);
        
        // 1. RECIBIMOS EL CÓDIGO (reservationCode)
        // Flutter lo envía así: body: { "reservationCode": "TURISGAL-TEST" }
        const { reservationCode } = req.body;

        // Si llega vacío
        if (!reservationCode) {
            return res.status(400).json({ 
                valid: false, 
                message: "Por favor, escanea un QR o escribe el código manualmente." 
            });
        }

        // 2. BUSCAMOS EN LA BASE DE DATOS
        // TRUCO: Buscamos en la columna 'reservationId' (BD) el valor que nos llegó en 'reservationCode' (App)
        const reservation = await prisma.reservation.findUnique({
            where: { reservationId: reservationCode }, 
            include: { user: true }
        });

        // 3. SI NO EXISTE ESE CÓDIGO EN LA BD
        if (!reservation) {
            return res.status(404).json({ 
                valid: false, 
                message: "No encontramos ninguna reserva con ese código." 
            });
        }

        // 4. SI YA SE HIZO EL CHECK-IN (Estado finalizado)
        // Bloqueamos si ya está completa o en curso
        const estadosFinalizados = ['REGISTRO_COMPLETADO', 'ACTIVA', 'COMPLETADA', 'PENDIENTE_REVISION'];
        
        if (estadosFinalizados.includes(reservation.status)) {
            console.log(`Check-in repetido bloqueado para: ${reservationCode}`);
            return res.status(400).json({ 
                valid: false, 
                // ESTE ES EL MENSAJE QUE VERÁS EN PANTALLA ROJA
                message: "¡Atención! El Check-in para esta reserva YA se ha realizado anteriormente."
            });
        }

        // 5. SI ESTÁ TODO BIEN (Está PENDIENTE)
        // Devolvemos 'valid: true' y los datos para la siguiente pantalla
        return res.json({ 
            valid: true, 
            message: "Reserva válida.",
            data: { 
                reservationId: reservation.reservationId, // Devolvemos el ID real
                guestName: reservation.guestName || "Huésped",
                checkInDate: reservation.checkInDate,
                checkOutDate: reservation.checkOutDate
            }
        });

    } catch (error) {
        console.error("Error en validateReservation:", error);
        return res.status(500).json({ message: "Error interno del servidor." });
    }
};
/**
 * ------------------------------------------------------------------
 * 2. VERIFICAR IDENTIDAD (SOLUCIÓN EMULADOR + MODO PRUEBAS)
 * ------------------------------------------------------------------
 */
const verifyIdentity = async (req, res) => {
    // Usamos 'let' para poder inyectar fotos falsas si el emulador falla
    let { reservationId, documentPhoto, selfiePhoto } = req.body;

    // 👇 CONFIGURACIÓN: true para Emulador, false para Producción (OCR Real)
    const MODO_PRUEBAS = true; 

    console.log(`📸 Solicitud de verificación para: ${reservationId}`);
    
    // --- PARCHE PARA EMULADOR ---
    if (MODO_PRUEBAS) {
        console.log(`[MODO PRUEBAS] Comprobando fotos...`);
        // Si el emulador no manda foto, ponemos una de relleno para que no falle la validación
        if (!documentPhoto) documentPhoto = "data:image/jpeg;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
        if (!selfiePhoto) selfiePhoto = "data:image/jpeg;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
    }

    if (!reservationId || !documentPhoto || !selfiePhoto) {
        return res.status(400).json({ message: "Faltan datos o fotografías." });
    }

    // --- MODO PRUEBAS (BYPASS OCR) ---
    if (MODO_PRUEBAS) {
        console.log(`[MODO PRUEBAS] Saltando OCR y guardando (Upsert)...`);
        
        try {
            // Usamos UPSERT para evitar error 500 si no existe el registro
            const updatedCheckin = await prisma.checkin.upsert({
                where: { reservationId: reservationId },
                update: {
                    documentPhoto: documentPhoto,
                    selfiePhoto: selfiePhoto,
                    checkinStatus: "IDENTIDAD_VERIFICADA", 
                    verifiedAt: new Date()
                },
                create: {
                    reservationId: reservationId,
                    checkinStatus: "IDENTIDAD_VERIFICADA",
                    guestName: "Huésped (Modo Pruebas)",
                    documentPhoto: documentPhoto,
                    selfiePhoto: selfiePhoto,
                    verifiedAt: new Date()
                }
            });

            return res.status(200).json({
                message: "Identidad verificada (MODO PRUEBAS).",
                data: {
                    checkinId: updatedCheckin.id,
                    status: updatedCheckin.checkinStatus,
                    extractedDni: "12345678Z (Simulado)"
                }
            });

        } catch (error) {
            console.error("ERROR BASE DE DATOS:", error); 
            return res.status(500).json({ message: "Error en base de datos", error: error.message });
        }
    }
    
    // --- MODO REAL (OCR) ---
    // (Este código se ejecutará cuando pongas MODO_PRUEBAS = false)
    console.log(`[OCR] Iniciando análisis real...`);

    try {
        const analisis = await analyzeDocumentReal(documentPhoto);

        if (!analisis.valid) {
            console.log(`Documento rechazado: ${analisis.reason}`);
            return res.status(400).json({ 
                message: "Documento no válido.", 
                reason: analisis.reason 
            });
        }

        console.log(`Documento Aceptado. DNI: ${analisis.dni}`);

        const updatedCheckin = await prisma.checkin.upsert({
            where: { reservationId: reservationId },
            update: {
                documentPhoto: documentPhoto,
                selfiePhoto: selfiePhoto,
                checkinStatus: "IDENTIDAD_VERIFICADA", 
                documentNumber: analisis.dni, 
                verifiedAt: new Date()
            },
            create: {
                reservationId: reservationId,
                checkinStatus: "IDENTIDAD_VERIFICADA",
                guestName: "Huésped",
                documentPhoto: documentPhoto,
                selfiePhoto: selfiePhoto,
                documentNumber: analisis.dni, 
                verifiedAt: new Date()
            }
        });

        res.status(200).json({
            message: "Identidad verificada correctamente.",
            data: {
                checkinId: updatedCheckin.id,
                status: updatedCheckin.checkinStatus,
                extractedDni: analisis.dni
            }
        });

    } catch (error) {
        console.error("Error en verificación de identidad:", error);
        res.status(500).json({ message: "Error procesando el documento.", error: error.message });
    }
};

/**
 * ------------------------------------------------------------------
 * FUNCION AUXILIAR: MOTOR DE ANÁLISIS OCR (Tesseract)
 * ------------------------------------------------------------------
 */
async function analyzeDocumentReal(base64Image) {
    const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, "");
    const buffer = Buffer.from(base64Data, 'base64');

    try {
        const { data: { text } } = await Tesseract.recognize(buffer, 'spa');
        const cleanedText = text.toUpperCase();

        const dniRegex = /\b(\d{8})[- ]?([A-Z])\b/;
        const dniMatch = cleanedText.match(dniRegex);

        if (!dniMatch) {
            return { valid: false, reason: "No se detecta un número de DNI legible." };
        }

        const numeroDNI = dniMatch[1];
        const letraDNI = dniMatch[2];
        const letrasValidas = "TRWAGMYFPDXBNJZSQVHLCKE";
        const letraCalculada = letrasValidas[numeroDNI % 23];

        if (letraCalculada !== letraDNI) {
            return { valid: false, reason: "DNI falso o mal leído (letra incorrecta)." };
        }

        const dateRegex = /(\d{2})[-/.](\d{2})[-/.](\d{4})/;
        const words = cleanedText.split(/\s+/);
        let expirationDate = null;

        const indexValidez = words.findIndex(w => w.includes("VALIDE") || w.includes("ALIDEZ"));
        if (indexValidez !== -1) {
            for (let i = 1; i <= 5; i++) {
                if (words[indexValidez + i]) {
                    const match = words[indexValidez + i].match(dateRegex);
                    if (match) {
                        expirationDate = new Date(match[3], match[2] - 1, match[1]);
                        break;
                    }
                }
            }
        }

        if (!expirationDate) {
            const allDates = cleanedText.match(new RegExp(dateRegex, 'g'));
            const today = new Date();
            if (allDates) {
                for (const dateStr of allDates) {
                    const parts = dateStr.match(dateRegex);
                    const d = new Date(parts[3], parts[2] - 1, parts[1]);
                    if (d > today && d.getFullYear() > 2020) {
                        expirationDate = d;
                        break;
                    }
                }
            }
        }

        if (!expirationDate) {
            return { valid: false, reason: "No se ha podido leer la fecha de caducidad." };
        }

        const today = new Date();
        if (expirationDate < today) {
            return { valid: false, reason: "El documento está caducado." };
        }

        return { 
            valid: true, 
            dni: `${numeroDNI}${letraDNI}`,
            expirationDate: expirationDate.toLocaleDateString()
        };

    } catch (error) {
        console.error("Error Tesseract:", error);
        return { valid: false, reason: "Fallo técnico al leer la imagen." };
    }
}

/**
 * ------------------------------------------------------------------
 * 3. FIRMAR Y FINALIZAR (Paso 3 del Frontend)
 * ------------------------------------------------------------------
 */
const submitSignature = async (req, res) => {
    const { 
        reservationId, 
        signatureBase64, 
        guestName, 
        acceptedTerms 
    } = req.body;

    if (!reservationId || !signatureBase64 || acceptedTerms === undefined) {
        return res.status(400).json({ message: "Faltan datos obligatorios." });
    }

    if (!acceptedTerms) {
        return res.status(403).json({ message: "Debes aceptar los términos." });
    }

    try {
        const previousCheckin = await prisma.checkin.findUnique({
            where: { reservationId: reservationId },
        });

        // Si no existe, creamos uno al vuelo (para evitar bloqueos en pruebas)
        if (!previousCheckin) {
             console.log("No había checkin previo, creando al vuelo para firmar...");
             await prisma.checkin.create({
                 data: {
                     reservationId: reservationId,
                     checkinStatus: "IDENTIDAD_VERIFICADA"
                 }
             });
        }
        
        const result = await prisma.$transaction(async (tx) => {
            const updatedCheckin = await tx.checkin.update({
                where: { reservationId: reservationId },
                data: {
                    signatureBase64: signatureBase64, 
                    acceptedTerms: acceptedTerms,   
                    checkinStatus: "COMPLETADO",
                    guestName: guestName,           
                    completedAt: new Date() 
                },
            });

            await tx.reservation.update({
                where: { reservationId: reservationId }, 
                data: {
                    status: "REGISTRO_COMPLETADO" 
                }
            });

            return updatedCheckin;
        });

        res.status(200).json({ 
            message: "Check-in completado exitosamente.",
            data: {
                checkinId: result.id,
                status: result.checkinStatus,
                message: `Bienvenido, ${result.guestName}. Check-in finalizado.`
            }
        });

    } catch (error) {
        console.error("Error finalizing check-in:", error);
        res.status(500).json({ message: "Error del servidor al finalizar." });
    }
};

module.exports = {
    validateReservation,
    verifyIdentity,
    submitSignature,
};