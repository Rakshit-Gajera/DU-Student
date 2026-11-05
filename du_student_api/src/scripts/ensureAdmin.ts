/**
 * Runs before the server starts when hosted. Creates the admin account from the
 * environment, or updates its password, so a public site never has a demo password.
 */
import { hashPassword } from '../services/auth.service';
import { prisma } from '../lib/prisma';

const MIN_PASSWORD_LENGTH = 12;

async function main(): Promise<void> {
  const password = process.env.ADMIN_PASSWORD;
  const username = process.env.ADMIN_USERNAME ?? 'admin';
  const email = (process.env.ADMIN_EMAIL ?? 'admin@example.com').toLowerCase();

  if (!password) {
    if ((await prisma.admin.count()) > 0) return;
    throw new Error('ADMIN_PASSWORD is required to create the first admin account');
  }
  if (password.length < MIN_PASSWORD_LENGTH) {
    throw new Error(`ADMIN_PASSWORD must be at least ${MIN_PASSWORD_LENGTH} characters`);
  }

  const passwordHash = await hashPassword(password);
  await prisma.admin.upsert({
    where: { username },
    update: { passwordHash, email },
    create: { username, email, name: 'Administrator', role: 'SUPERADMIN', passwordHash },
  });
  console.log(`Admin account "${username}" is ready.`);
}

main()
  .catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => {
    void prisma.$disconnect();
  });
