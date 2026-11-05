import { createApp } from './app';
import { config } from './config';
import { prisma } from './lib/prisma';

const server = createApp().listen(config.port, () => {
  console.log(`du_student_api listening on http://localhost:${config.port}`);
});

async function shutdown(signal: string): Promise<void> {
  console.log(`${signal} received, shutting down`);
  server.close();
  await prisma.$disconnect();
  process.exit(0);
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
