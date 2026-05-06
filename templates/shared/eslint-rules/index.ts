import { noUnsafeZodParse } from './no-unsafe-zod-parse.ts';
import { noDirectTimeRandomness } from './no-direct-time-randomness.ts';

export const rules = {
  'no-unsafe-zod-parse': noUnsafeZodParse,
  'no-direct-time-randomness': noDirectTimeRandomness,
};

export default { rules };
