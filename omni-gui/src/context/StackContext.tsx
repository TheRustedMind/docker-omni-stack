import { createContext, useContext, useState, useEffect, ReactNode } from "react";
import { invoke } from "@tauri-apps/api/core";
import { RegistryService } from "../lib/types";

interface StackContextType {
  services: Record<string, RegistryService>;
  statuses: Record<string, string>;
  loading: boolean;
  darkMode: boolean;
  setDarkMode: (val: boolean) => void;
  useDockerVolumes: boolean;
  setUseDockerVolumes: (val: boolean) => void;
  isDockerRunning: boolean | null;
  isStartingDocker: boolean;
  isGlobalStarting: boolean;
  isGlobalStopping: boolean;
  
  checkDocker: () => Promise<void>;
  handleStartDocker: () => Promise<void>;
  fetchServices: () => Promise<void>;
  checkStatus: (serviceName: string) => Promise<void>;
  startStack: () => Promise<void>;
  stopStack: () => Promise<void>;
  trustCertificate: () => Promise<void>;
  toggleService: (serviceName: string, isCurrentlyRunning: boolean) => Promise<void>;
  executeDirectRestart: (targetService: string, extraServices: string[]) => Promise<void>;
}

const StackContext = createContext<StackContextType | undefined>(undefined);

export function StackProvider({ children }: { children: ReactNode }) {
  const [services, setServices] = useState<Record<string, RegistryService>>({});
  const [statuses, setStatuses] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [darkMode, setDarkMode] = useState(true);
  const [useDockerVolumes, setUseDockerVolumes] = useState(true);
  const [isDockerRunning, setIsDockerRunning] = useState<boolean | null>(null);
  const [isStartingDocker, setIsStartingDocker] = useState(false);
  
  const [isGlobalStarting, setIsGlobalStarting] = useState(false);
  const [isGlobalStopping, setIsGlobalStopping] = useState(false);

  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [darkMode]);

  const checkDocker = async () => {
    try {
      const status = await invoke<boolean>("check_docker_status");
      setIsDockerRunning(status);
      if (status) setIsStartingDocker(false);
    } catch (e) {
      setIsDockerRunning(false);
    }
  };

  const handleStartDocker = async () => {
    setIsStartingDocker(true);
    try {
      await invoke("start_docker_engine");
    } catch (e) {
      console.error(e);
      setIsStartingDocker(false);
    }
  };

  const checkStatus = async (serviceName: string) => {
    try {
      const status: string = await invoke("get_container_status", { service: serviceName });
      setStatuses((prev) => ({ ...prev, [serviceName]: status }));
    } catch (e) {
      console.error(e);
    }
  };

  const fetchServices = async () => {
    try {
      const data: Record<string, RegistryService> = await invoke("get_registry");
      setServices(data);
      await Promise.all(Object.keys(data).map(key => checkStatus(key)));
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const executeDirectRestart = async (targetService: string, extraServices: string[]) => {
    setStatuses(prev => ({ ...prev, [targetService]: "Toggling (Down)" }));
    extraServices.forEach(s => setStatuses(prev => ({ ...prev, [s]: "Toggling (Down)" })));
    try {
      const allToRestart = [targetService, ...extraServices];
      await invoke("execute_restart", { services: allToRestart });
      allToRestart.forEach(s => {
        setTimeout(() => checkStatus(s), 1500);
        setTimeout(() => checkStatus(s), 5000);
      });
    } catch (e) {
      alert(`Restart failed: ${e}`);
    }
  };

  const getCurrentlyRunning = () => {
    return Object.entries(statuses)
      .filter(([_, status]) => status.startsWith("Up") || status.startsWith("Running") || status === "Toggling (Up)")
      .map(([name]) => name);
  };

  const toggleService = async (serviceName: string, isCurrentlyRunning: boolean) => {
    try {
      if (!isCurrentlyRunning) {
        setStatuses((prev) => ({ ...prev, [serviceName]: "Toggling (Up)" }));
        setStatuses((prev) => {
            const running = Object.entries(prev)
                .filter(([_, status]) => status.startsWith("Up") || status.startsWith("Running") || status === "Toggling (Up)")
                .map(([name]) => name);
            const nextServices = Array.from(new Set([...running, serviceName]));
            invoke("execute_up", { services: nextServices })
                .then(() => {
                    setTimeout(() => checkStatus(serviceName), 1500);
                    setTimeout(() => checkStatus(serviceName), 5000);
                })
                .catch((e) => {
                    alert(`Failed to start ${serviceName}: ${e}`);
                    checkStatus(serviceName);
                });
            return prev;
        });
      } else {
        setStatuses((prev) => ({ ...prev, [serviceName]: "Toggling (Down)" }));
        setStatuses((prev) => {
            const running = Object.entries(prev)
                .filter(([_, status]) => status.startsWith("Up") || status.startsWith("Running") || status === "Toggling (Up)")
                .map(([name]) => name);
            const nextServices = running.filter((s) => s !== serviceName);
            
            invoke("execute_stop", { service: serviceName })
                .then(() => invoke("execute_up", { services: nextServices }))
                .then(() => {
                    setTimeout(() => checkStatus(serviceName), 1500);
                    setTimeout(() => checkStatus(serviceName), 5000);
                })
                .catch((e) => {
                    alert(`Failed to stop ${serviceName}: ${e}`);
                    checkStatus(serviceName);
                });
            return prev;
        });
      }
    } catch (e) {
      alert(e);
      checkStatus(serviceName);
    }
  };

  const startStack = async () => {
    setIsGlobalStarting(true);
    setStatuses((prev) => ({ ...prev, caddy: "Toggling..." }));
    try {
      await invoke("execute_setup", { useVolumes: useDockerVolumes });
      await invoke("execute_up", { services: ["caddy"] });
      await checkStatus("caddy");
      setTimeout(() => checkStatus("caddy"), 5000);
    } catch (e) {
      alert(`Stack action failed: ${e}`);
      checkStatus("caddy");
    } finally {
      setIsGlobalStarting(false);
    }
  };

  const stopStack = async () => {
    setIsGlobalStopping(true);
    const running = getCurrentlyRunning();
    const newStatuses = { ...statuses };
    running.forEach((s) => (newStatuses[s] = "Toggling..."));
    setStatuses(newStatuses);

    try {
      await invoke("execute_down");
      await Promise.all(Object.keys(services).map((s) => checkStatus(s)));
      Object.keys(services).forEach((s) => {
        setTimeout(() => checkStatus(s), 5000);
      });
    } catch (e) {
      alert(`Stack action failed: ${e}`);
      Object.keys(services).forEach((s) => checkStatus(s));
    } finally {
      setIsGlobalStopping(false);
    }
  };

  const trustCertificate = async () => {
    try {
      await invoke("trust_certificate");
    } catch (e) {
      alert(`Operation failed: ${e}`);
    }
  };

  useEffect(() => {
    checkDocker();
    fetchServices();
  }, []);

  useEffect(() => {
    const serviceNames = Object.keys(services);
    
    const intervalId = setInterval(() => {
      checkDocker();
      if (serviceNames.length > 0) {
        serviceNames.forEach((name) => checkStatus(name));
      }
    }, 3000);

    return () => clearInterval(intervalId);
  }, [services]);

  const value = {
    services,
    statuses,
    loading,
    darkMode,
    setDarkMode,
    useDockerVolumes,
    setUseDockerVolumes,
    isDockerRunning,
    isStartingDocker,
    isGlobalStarting,
    isGlobalStopping,
    checkDocker,
    handleStartDocker,
    fetchServices,
    checkStatus,
    startStack,
    stopStack,
    trustCertificate,
    toggleService,
    executeDirectRestart
  };

  return <StackContext.Provider value={value}>{children}</StackContext.Provider>;
}

export function useStackContext() {
  const context = useContext(StackContext);
  if (context === undefined) {
    throw new Error("useStackContext must be used within a StackProvider");
  }
  return context;
}
