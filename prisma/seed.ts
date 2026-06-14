import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  const adminEmail = 'admin@confirmaid.local'
  const existing = await prisma.user.findUnique({ where: { email: adminEmail } })

  if (!existing) {
    const passwordHash = await bcrypt.hash('Admin123!@#', 10)
    await prisma.user.create({
      data: {
        name: 'Admin ConfirmaID',
        email: adminEmail,
        cpf: '00000000000',
        birthDate: new Date('1990-01-01'),
        passwordHash,
        role: 'ADMIN',
        status: 'ACTIVE',
      },
    })
    console.log('✅ Admin user created: admin@confirmaid.local / Admin123!@#')
  } else {
    console.log('Admin user already exists')
  }

  const testEmail = 'user@confirmaid.local'
  if (!(await prisma.user.findUnique({ where: { email: testEmail } }))) {
    const hash = await bcrypt.hash('User123!@#', 10)
    await prisma.user.create({
      data: {
        name: 'Test User',
        email: testEmail,
        cpf: '11111111111',
        birthDate: new Date('1995-05-15'),
        passwordHash: hash,
        role: 'USER',
        status: 'ACTIVE',
      },
    })
    console.log('✅ Test USER created: user@confirmaid.local / User123!@#')
  }
}

main()
  .then(async () => {
    await prisma.$disconnect()
  })
  .catch(async (e) => {
    console.error(e)
    await prisma.$disconnect()
    process.exit(1)
  })
