'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function RegisterPage() {
  const [form, setForm] = useState({
    name: '',
    email: '',
    cpf: '',
    birthDate: '',
    phone: '',
    password: '',
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    // For now, simple client-side registration via API route (to be implemented in next steps)
    // Placeholder: for MVP Fase 2 we show the form and redirect after "success"
    try {
      // TODO: Call /api/register when we implement the route
      console.log('Registration data (Fase 2 base):', form)
      
      // Temporary: redirect to login with success message
      router.push('/login?registered=true')
    } catch (err) {
      setError('Erro ao cadastrar. Tente novamente.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white p-8 shadow">
        <h1 className="text-2xl font-bold mb-2">Criar conta no ConfirmaID</h1>
        <p className="text-sm text-gray-600 mb-6">
          Cadastre-se para iniciar a verificação da sua identidade.
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            name="name"
            placeholder="Nome completo"
            value={form.name}
            onChange={handleChange}
            required
            className="w-full border rounded px-3 py-2"
          />
          <input
            name="email"
            type="email"
            placeholder="E-mail"
            value={form.email}
            onChange={handleChange}
            required
            className="w-full border rounded px-3 py-2"
          />
          <input
            name="cpf"
            placeholder="CPF (somente números)"
            value={form.cpf}
            onChange={handleChange}
            required
            className="w-full border rounded px-3 py-2"
          />
          <input
            name="birthDate"
            type="date"
            value={form.birthDate}
            onChange={handleChange}
            required
            className="w-full border rounded px-3 py-2"
          />
          <input
            name="phone"
            placeholder="Celular"
            value={form.phone}
            onChange={handleChange}
            className="w-full border rounded px-3 py-2"
          />
          <input
            name="password"
            type="password"
            placeholder="Senha (mínimo 6 caracteres)"
            value={form.password}
            onChange={handleChange}
            required
            minLength={6}
            className="w-full border rounded px-3 py-2"
          />

          {error && <div className="text-red-600 text-sm">{error}</div>}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-green-600 text-white py-2 rounded font-semibold hover:bg-green-700 disabled:opacity-50"
          >
            {loading ? 'Criando conta...' : 'Criar minha conta'}
          </button>
        </form>

        <p className="text-center text-sm mt-4">
          Já tem conta? <a href="/login" className="text-blue-600">Entrar</a>
        </p>
      </div>
    </div>
  )
}
