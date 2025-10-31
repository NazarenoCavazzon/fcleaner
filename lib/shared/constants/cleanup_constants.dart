class CleanupConstants {
  static const defaultWhitelistPatterns = [
    '~/Library/Caches/ms-playwright*',
    '~/.cache/huggingface*',
    '~/.m2/repository/*',
    '~/.ollama/models/*',
  ];

  static const tempFileAgeDays = 7;
  static const orphanDataAgeDays = 60;
  static const maxParallelJobs = 15;

  static const configDirectory = '~/.config/fcleaner';
  static const whitelistFileName = 'whitelist';

  static const categoryIds = {
    'system_essentials': 'System Essentials',
    'macos_system_caches': 'macOS System Caches',
    'sandboxed_apps': 'Sandboxed Apps',
    'browsers': 'Browsers',
    'cloud_storage': 'Cloud Storage',
    'office_apps': 'Office Applications',
    'developer_tools': 'Developer Tools',
    'extended_dev_tools': 'Extended Developer Tools',
    'applications': 'Applications',
    'virtualization': 'Virtualization Tools',
    'orphaned_data': 'Orphaned App Data',
    'apple_silicon': 'Apple Silicon Optimizations',
  };
}
