import { HttpInterceptorFn } from '@angular/common/http';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = getStoredToken();

  if (!token) {
    return next(req);
  }

  return next(req.clone({
    setHeaders: {
      Authorization: `Bearer ${token}`
    }
  }));
};

function getStoredToken(): string | null {
  if (typeof window === 'undefined') {
    return null;
  }

  const keys = ['token', 'accessToken', 'authToken', 'jwt'];
  for (const key of keys) {
    const token = window.localStorage.getItem(key) ?? window.sessionStorage.getItem(key);
    if (token) {
      return token;
    }
  }

  return null;
}
