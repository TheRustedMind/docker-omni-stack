export interface RegistryService {
  ComposeFile: string;
  EnvFile: string;
  DependsOn: string[];
  Group: string;
  InternalPort?: number;
}

export interface VolumeInfo {
  mount_type: string;
  name_or_source: string;
  destination: string;
}
