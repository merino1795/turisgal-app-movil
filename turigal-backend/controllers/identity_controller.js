const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// ==========================================================
// MÓDULOS DE INTEGRACIÓN EXTERNA (SERVICIOS REALES)
// ==========================================================

/**
 * Módulo para gestionar el almacenamiento de imágenes.
 * En producción: Usar AWS S3, Google Cloud Storage o Cloudinary.
 * En desarrollo local: Guardamos el Base64 directo o en disco.
 */
const cloudStorageModule = {
    uploadBase64Image: async (base64Data, type, reservationId) => {
        
        console.log(`[STORAGE] Subiendo imagen tipo '${type}' para reserva ${reservationId}...`);
        
        // Simulación de latencia de red real (500ms)
        await new Promise(resolve => setTimeout(resolve, 500));

        return base64Data; // Guardamos el dato crudo por ahora
    },
};

/**
 * Módulo para verificación biométrica y OCR.
 * En producción: Usar Google Vision API, AWS Rekognition o servicios como Jumio/Onfido.
 */
const biometricService = {
    verifyAndExtractIdentity: async (documentBase64, selfieBase64) => {
        // TODO: Llamar a API externa de OCR
        console.log("[BIOMETRIC] Analizando documentos con IA...");
        
        // Simulación de tiempo de procesamiento (1.5s)
        await new Promise(resolve => setTimeout(resolve, 1500)); 
        
        // Simulamos que la IA leyó el DNI correctamente
        return {
            isVerified: true,
            documentNumber: `DNI-${Math.floor(Math.random() * 90000000)}T`, // Dato extraído simulado
            documentType: "DNI Español",
            extractedName: "Huésped Verificado", // En producción, esto vendría del OCR del DNI
            confidenceScore: 0.98
        };
    }
};

/**
 * Endpoint: POST /api/checkin/verify-identity
 * Descripción: Recibe las fotos, las procesa y actualiza el estado del check-in.
 */
const verifyIdentity = async (req, res) => {
    const { reservationId, documentBase64, selfieBase64 } = req.body;

    // 1. Validación de Entrada
    if (!reservationId || !documentBase64 || !selfieBase64) {
        return res.status(400).json({ 
            message: "Faltan datos obligatorios (ID, DNI o Selfie).",
            status: "error"
        });
    }

    try {
        // 2. Verificar que existe el proceso de check-in iniciado (del paso 1)
        const checkinRecord = await prisma.checkin.findUnique({
            where: { reservationId: reservationId }
        });

        if (!checkinRecord) {
            // Si no existe (el usuario se saltó el paso 1 o la BD está limpia), lo creamos
            // Esto hace el sistema más robusto
            await prisma.checkin.create({
                data: {
                    reservationId: reservationId,
                    checkinStatus: "INICIADO",
                    guestName: "Huésped (Provisorio)"
                }
            });
        }

        // 3. Procesamiento de Imágenes (Llamadas a servicios externos)
        const verificationResult = await biometricService.verifyAndExtractIdentity(documentBase64, selfieBase64);
        
        if (!verificationResult.isVerified) {
            return res.status(400).json({ 
                message: "La verificación de identidad ha fallado. La foto no coincide o no es legible.",
                status: "failed" 
            });
        }

        // 4. Subida de Archivos (Storage)
        const documentImageUrl = await cloudStorageModule.uploadBase64Image(documentBase64, 'document', reservationId);
        const selfieImageUrl = await cloudStorageModule.uploadBase64Image(selfieBase64, 'selfie', reservationId);

        // 5. Actualización en Base de Datos
        await prisma.checkin.update({
            where: { reservationId: reservationId }, // Usamos reservationId que es único
            data: {
                // Guardamos los datos extraídos por la IA
                documentNumber: verificationResult.documentNumber,
                documentType: verificationResult.documentType,
                // Guardamos las referencias a las imágenes (URLs o Base64)
                documentPhoto: documentImageUrl, // Asegúrate que tu schema.prisma tiene este campo
                selfiePhoto: selfieImageUrl,     // Asegúrate que tu schema.prisma tiene este campo
                // Actualizamos estado
                checkinStatus: "IDENTIDAD_VERIFICADA", 
                guestName: verificationResult.extractedName, // Actualizamos el nombre real
                verifiedAt: new Date()
            },
        });

        // 6. Respuesta Exitosa
        res.status(200).json({ 
            message: "Identidad verificada correctamente.",
            data: {
                reservationId,
                verifiedName: verificationResult.extractedName,
                status: "success"
            }
        });

    } catch (error) {
        console.error("Error en verifyIdentity:", error);
        res.status(500).json({ message: "Error interno procesando la identidad.", status: "error" });
    }
};

module.exports = {
    verifyIdentity,
};