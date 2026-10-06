const crypto = require('crypto');

function createAuth({ app, ttlSeconds = 900, refreshTtlSeconds = 7 * 24 * 3600 }) {
  let nextUserId = 5;
  const users = [
    { id: 1, username: 'viewer', password: 'viewer123!', displayName: 'Иван Просмотр', role: 'viewer' },
    { id: 2, username: 'operator', password: 'operator1!', displayName: 'Ольга Кладовщик', role: 'operator' },
    { id: 3, username: 'admin', password: 'admin123!', displayName: 'Админ Системы', role: 'admin' },
    { id: 4, username: 'masha', password: 'masha123!', displayName: 'Маша', role: 'viewer' },
  ];

  const roleLevel = { viewer: 1, operator: 2, admin: 3 };

  function b64(obj) {
    return Buffer.from(JSON.stringify(obj)).toString('base64url');
  }

  function parseB64(token) {
    try {
      return JSON.parse(Buffer.from(token, 'base64url').toString('utf8'));
    } catch {
      return null;
    }
  }

  function issueTokens(user) {
    const now = Math.floor(Date.now() / 1000);
    const accessToken = b64({
      typ: 'access',
      sub: user.id,
      username: user.username,
      role: user.role,
      displayName: user.displayName,
      exp: now + ttlSeconds,
    });
    const refreshToken = b64({
      typ: 'refresh',
      sub: user.id,
      exp: now + refreshTtlSeconds,
      jti: crypto.randomBytes(8).toString('hex'),
    });
    return { accessToken, refreshToken, expiresIn: ttlSeconds };
  }

  function publicUser(u) {
    return {
      id: u.id,
      username: u.username,
      displayName: u.displayName,
      role: u.role,
    };
  }

  function readBearer(req) {
    const h = req.headers.authorization || '';
    const m = /^Bearer\s+(.+)$/i.exec(h);
    return m ? m[1] : null;
  }

  function authRequired(req, res, next) {
    const token = readBearer(req);
    if (!token) {
      return res.status(401).json({ message: 'Требуется вход в систему.' });
    }
    const payload = parseB64(token);
    if (!payload || payload.typ !== 'access') {
      return res.status(401).json({ message: 'Недействительный токен.' });
    }
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      return res.status(401).json({ message: 'Срок действия токена истёк.' });
    }
    const user = users.find((u) => u.id === payload.sub);
    if (!user) {
      return res.status(401).json({ message: 'Пользователь не найден.' });
    }
    req.user = user;
    req.tokenPayload = payload;
    next();
  }

  function requireRole(minRole) {
    return (req, res, next) => {
      const need = roleLevel[minRole] || 99;
      const have = roleLevel[req.user?.role] || 0;
      if (have < need) {
        return res.status(403).json({
          message: `Недостаточно прав (нужна роль «${minRole}» или выше).`,
        });
      }
      next();
    };
  }

  app.post('/api/auth/login', (req, res) => {
    const username = String(req.body?.username || '').trim();
    const password = String(req.body?.password || '');
    const user = users.find((u) => u.username === username && u.password === password);
    if (!user) {
      return res.status(401).json({ message: 'Неверный логин или пароль.' });
    }
    const tokens = issueTokens(user);
    res.json({ ...tokens, user: publicUser(user) });
  });

  app.post('/api/auth/register', (req, res) => {
    const username = String(req.body?.username || '').trim();
    const password = String(req.body?.password || '');
    const displayName = String(req.body?.displayName || '').trim();
    const errors = {};
    if (username.length < 3) errors.username = 'Логин не короче 3 символов';
    if (users.some((u) => u.username === username)) errors.username = 'Логин уже занят';
    if (displayName.length < 2) errors.displayName = 'Укажите имя';
    if (password.length < 8) errors.password = 'Пароль не короче 8 символов';
    else if (!/\d/.test(password)) errors.password = 'Нужна хотя бы одна цифра';
    else if (!/[^A-Za-zА-Яа-я0-9]/.test(password)) {
      errors.password = 'Нужен специальный символ';
    }
    if (Object.keys(errors).length) {
      return res.status(422).json({ message: 'Ошибка валидации', errors });
    }
    const user = {
      id: nextUserId++,
      username,
      password,
      displayName,
      role: 'viewer',
    };
    users.push(user);
    const tokens = issueTokens(user);
    res.status(201).json({ ...tokens, user: publicUser(user) });
  });

  app.post('/api/auth/refresh', (req, res) => {
    const refresh = String(req.body?.refreshToken || '');
    const payload = parseB64(refresh);
    if (!payload || payload.typ !== 'refresh') {
      return res.status(401).json({ message: 'Недействительный refresh-токен.' });
    }
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      return res.status(401).json({ message: 'Refresh-токен истёк.' });
    }
    const user = users.find((u) => u.id === payload.sub);
    if (!user) return res.status(401).json({ message: 'Пользователь не найден.' });
    const tokens = issueTokens(user);
    res.json({ ...tokens, user: publicUser(user) });
  });

  app.get('/api/auth/me', authRequired, (req, res) => {
    res.json(publicUser(req.user));
  });

  app.get('/api/admin/users', authRequired, requireRole('admin'), (_req, res) => {
    res.json({ items: users.map(publicUser), total: users.length });
  });

  function setUserRole(req, res) {
    const id = Number(req.params.id);
    const role = String(req.body?.role || '');
    if (!roleLevel[role]) {
      return res.status(422).json({
        message: 'Ошибка валидации',
        errors: { role: 'Допустимы viewer, operator, admin' },
      });
    }
    const user = users.find((u) => u.id === id);
    if (!user) return res.status(404).json({ message: 'Пользователь не найден' });
    user.role = role;
    res.json(publicUser(user));
  }

  app.patch('/api/admin/users/:id/role', authRequired, requireRole('admin'), setUserRole);
  app.put('/api/admin/users/:id/role', authRequired, requireRole('admin'), setUserRole);

  let statsProvider = () => ({ products: 0, suppliers: 0, warehouses: 0, users: users.length });

  app.get('/api/admin/stats', authRequired, requireRole('admin'), (_req, res) => {
    res.json(statsProvider());
  });

  app.get('/api/viewer/requests', authRequired, (req, res) => {
    if ((roleLevel[req.user.role] || 0) !== roleLevel.viewer && req.user.role !== 'viewer') {
      // allow only pure viewer for unique screen? Assignment: each role has unique screen.
      // viewer-only: if operator/admin hit this, 403
    }
    if (req.user.role !== 'viewer') {
      return res.status(403).json({ message: 'Раздел доступен только наблюдателю (viewer).' });
    }
    res.json({
      items: [
        { id: 1, title: 'Заявка на сверку остатков', status: 'открыта', createdAt: '2026-10-01' },
        { id: 2, title: 'Запрос продления резерва', status: 'в работе', createdAt: '2026-10-03' },
      ],
    });
  });

  return {
    authRequired,
    requireRole,
    setStatsProvider(fn) {
      statsProvider = () => ({ ...fn(), users: users.length });
    },
    ttlSeconds,
  };
}

module.exports = { createAuth };
