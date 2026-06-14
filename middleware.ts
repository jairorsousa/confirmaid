import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { auth } from './lib/auth'

const protectedRoutes = {
  '/(citizen)': ['USER'],
  '/(partner)': ['PARTNER'],
  '/(admin)': ['ANALYST', 'ADMIN'],
}

export default auth(async (req) => {
  const { nextUrl } = req
  const session = req.auth

  const isProtected = Object.keys(protectedRoutes).some((route) =>
    nextUrl.pathname.startsWith(route.replace(/[()]/g, ''))
  )

  if (isProtected && !session?.user) {
    const loginUrl = new URL('/login', nextUrl)
    loginUrl.searchParams.set('callbackUrl', nextUrl.pathname)
    return NextResponse.redirect(loginUrl)
  }

  if (session?.user && isProtected) {
    const path = nextUrl.pathname
    let allowedRoles: string[] = []

    if (path.startsWith('/citizen')) allowedRoles = protectedRoutes['/(citizen)']
    if (path.startsWith('/partner')) allowedRoles = protectedRoutes['/(partner)']
    if (path.startsWith('/admin')) allowedRoles = protectedRoutes['/(admin)']

    if (allowedRoles.length > 0 && !allowedRoles.includes(session.user.role)) {
      return NextResponse.redirect(new URL('/unauthorized', nextUrl))
    }
  }

  return NextResponse.next()
})

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|login|register).*)'],
}
