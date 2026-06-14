'use client'

import { useState } from 'react'
import { signIn } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input' // will be added via shadcn if needed

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    const result = await signIn('credentials', {
      email,
      password,
      redirect: false,
    })

    if (result?.error) {
      setError(result.error)
      setLoading(false)
    } else {
      router.push('/citizen') // default redirect for USER
      router.refresh()
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-md space-y-8 rounded-xl bg-white p-8 shadow">
        <div>
          <h1 className="text-2xl font-bold text-center">Entrar no ConfirmaID</h1>
          <p className="text-center text-sm text-gray-600 mt-2">
            Acesse sua conta para verificar sua identidade ou consultar como parceiro.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium">E-mail</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="mt-1 block w-full rounded-md border px-3 py-2"
              placeholder="seu@email.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium">Senha</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="mt-1 block w-full rounded-md border px-3 py-2"
              placeholder="••••••••"
            />
          </div>

          {error && (
            <div className="rounded bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? 'Entrando...' : 'Entrar'}
          </Button>
        </form>

        <p className="text-center text-sm">
          Não tem conta?{' '}
          <a href="/register" className="text-blue-600 hover:underline">
            Cadastre-se
          </a>
        </p>

        <div className="text-xs text-gray-500 text-center">
          Usuário teste: user@confirmaid.local / User123!@# <br />
          Admin: admin@confirmaid.local / Admin123!@#
        </div>
      </div>
    </div>
  )
}
