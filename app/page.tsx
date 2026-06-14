import Link from 'next/link'

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8 bg-gray-50">
      <div className="max-w-md w-full text-center">
        <h1 className="text-4xl font-bold mb-2">ConfirmaID</h1>
        <p className="text-xl text-gray-600 mb-8">Identidade verificada, simples, segura e reutilizável.</p>

        <div className="space-y-3">
          <Link 
            href="/login" 
            className="block w-full bg-[#22C55E] hover:bg-[#16A34A] text-white font-semibold py-3 px-6 rounded-lg transition"
          >
            Entrar
          </Link>
          <Link 
            href="/register" 
            className="block w-full border border-gray-300 hover:bg-gray-100 font-semibold py-3 px-6 rounded-lg transition"
          >
            Criar conta (Cidadão)
          </Link>
        </div>

        <p className="mt-8 text-xs text-gray-500">
          Para parceiros e administradores, acesse após login.
        </p>
      </div>
    </div>
  )
}
