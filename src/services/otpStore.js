const otps = new Map();

const set = (email, otp, expiresInMs = 10 * 60 * 1000) => {
  otps.set(email, { otp, expiresAt: Date.now() + expiresInMs });
};

const get = (email) => {
  const entry = otps.get(email);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) { otps.delete(email); return null; }
  return entry.otp;
};

const remove = (email) => otps.delete(email);

module.exports = { set, get, remove };