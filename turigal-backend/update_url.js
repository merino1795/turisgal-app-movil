const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("🔄 Actualizando reserva TURISGAL-TEST...");

  try {
    // Aquí ponemos una URL real de un apartamento de Turisgal
    // He cogido una al azar de su web para que funcione el scraper
    const urlReal = "https://turisgal.com/vivienda-vacacional/alquiler-vacacional-con-vistas-2/"; 

    const updated = await prisma.reservation.update({
      where: { reservationId: "TURISGAL-TEST" },
      data: { 
        propertyUrl: urlReal 
      }
    });

    console.log("¡ÉXITO! URL insertada correctamente.");
    console.log("URL:", updated.propertyUrl);
  } catch (e) {
    console.error("Error actualizando:", e);
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });