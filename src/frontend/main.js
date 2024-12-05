import { Auth } from './auth.js';
import { updateBalance } from './cycles-balance.js';

const init = async () => {
  const auth = new Auth();
  await auth.init();
  await updateBalance();
};

init().catch(console.error);