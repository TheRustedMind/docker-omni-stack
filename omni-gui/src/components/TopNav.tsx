import { Button } from "@/components/ui/button";
import { ShieldCheck, Moon, Sun, Square } from "lucide-react";
import { useStackContext } from "../context/StackContext";

export function TopNav() {
  const { darkMode, setDarkMode, trustCertificate, stopStack, statuses, isGlobalStopping } = useStackContext();
  
  const caddyStatus = statuses["caddy"] || "Unknown";
  const caddyIsRunning = caddyStatus.startsWith("Up") || caddyStatus.startsWith("Running");

  return (
    <div className="sticky top-0 z-40 backdrop-blur-md bg-background/80 border-b border-border shadow-sm">
      <div className="max-w-7xl mx-auto px-6 h-16 flex justify-between items-center">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
            <span className="text-primary-foreground font-bold text-xl">O</span>
          </div>
          <h1 className="text-xl font-bold tracking-tight">Omni Stack</h1>
        </div>
        
        <div className="flex items-center space-x-4">
          <Button variant="outline" onClick={trustCertificate} disabled={!caddyIsRunning} className="shadow-sm font-medium cursor-pointer">
            <ShieldCheck className="mr-2 h-4 w-4" /> Trust HTTPS
          </Button>
          <Button variant="ghost" size="icon" onClick={() => setDarkMode(!darkMode)} className="rounded-full cursor-pointer">
            {darkMode ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
          </Button>
          <Button variant="destructive" onClick={stopStack} disabled={caddyStatus === "Toggling..." || isGlobalStopping} className="shadow-sm font-medium cursor-pointer">
            <Square className="mr-2 h-4 w-4 fill-current" /> Stop Stack
          </Button>
        </div>
      </div>
    </div>
  );
}
