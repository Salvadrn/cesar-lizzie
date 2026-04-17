import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@adaptai/shared-types', '@adaptai/shared-constants'],
};

export default nextConfig;
