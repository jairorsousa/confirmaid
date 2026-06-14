export default function CitizenDashboard() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold">Área do Cidadão</h1>
      <p className="mt-4">Bem-vindo! Aqui você iniciará a verificação da sua identidade.</p>
      <div className="mt-8 p-4 bg-green-50 rounded">
        <p className="text-sm">Status: <span className="font-semibold">Verificação pendente</span></p>
      </div>
    </div>
  )
}
