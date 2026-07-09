import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { ConceptType, PrismaClient } from '../src/generated/prisma/client';
import { systemConcepts } from './data/system-concepts';

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL is not set');
  }

  const adapter = new PrismaPg({ connectionString });
  const prisma = new PrismaClient({ adapter });

  try {
    for (const concept of systemConcepts) {
      await prisma.concept.upsert({
        where: { id: concept.id },
        create: {
          id: concept.id,
          userId: null,
          type: concept.type,
          title: concept.title,
          emoji: concept.emoji,
          category: concept.category,
          description: concept.description,
          missionPrompt: concept.missionPrompt,
          themeColorHex: concept.themeColorHex,
          sourceTemplateId: null,
        },
        update: {
          userId: null,
          type: concept.type,
          title: concept.title,
          emoji: concept.emoji,
          category: concept.category,
          description: concept.description,
          missionPrompt: concept.missionPrompt,
          themeColorHex: concept.themeColorHex,
          sourceTemplateId: null,
        },
      });
    }

    const count = await prisma.concept.count({
      where: { type: ConceptType.SYSTEM },
    });

    console.log(`Seeded ${count} system concepts.`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error: unknown) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
