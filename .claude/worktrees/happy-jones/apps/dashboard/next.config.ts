import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@neuronav/shared-types', '@neuronav/shared-constants'],
};

export default nextConfig;
