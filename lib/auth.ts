import NextAuth from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { prisma } from './db'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
})

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Credentials({
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      authorize: async (credentials) => {
        const parsed = loginSchema.safeParse(credentials)
        if (!parsed.success) {
          throw new Error('Invalid credentials')
        }

        const { email, password } = parsed.data

        const user = await prisma.user.findUnique({
          where: { email },
        })

        if (!user) {
          throw new Error('User not found')
        }

        const isValid = await bcrypt.compare(password, user.passwordHash)
        if (!isValid) {
          throw new Error('Invalid password')
        }

        if (user.status !== 'ACTIVE') {
          throw new Error('Account is not active')
        }

        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        }
      },
    }),
  ],
  session: {
    strategy: 'jwt',
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = user.role
        token.id = user.id
      }
      return token
    },
    async session({ session, token }) {
      if (token) {
        session.user.id = token.id as string
        session.user.role = token.role as 'USER' | 'PARTNER' | 'ANALYST' | 'ADMIN'
      }
      return session
    },
  },
  pages: {
    signIn: '/login',
  },
})

declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      name?: string | null
      email?: string | null
      image?: string | null
      role: 'USER' | 'PARTNER' | 'ANALYST' | 'ADMIN'
    }
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    id: string
    role: 'USER' | 'PARTNER' | 'ANALYST' | 'ADMIN'
  }
}
