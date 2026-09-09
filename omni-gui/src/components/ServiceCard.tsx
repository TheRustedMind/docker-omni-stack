import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Loader2, Copy, Check, RefreshCw } from "lucide-react";
import { useStackContext } from "../context/StackContext";
import { SERVICE_DESCRIPTIONS, DB_PORTS } from "../lib/constants";
import { MockupSlider } from "./MockupSlider";

interface ServiceCardProps {
  name: string;
  onOpenEnv: (name: string) => void;
  onOpenVolume: (name: string) => void;
  onOpenRestart: (name: string) => void;
}

export function ServiceCard({ name, onOpenEnv, onOpenVolume, onOpenRestart }: ServiceCardProps) {
  const { services, statuses, toggleService } = useStackContext();
  const [copiedText, setCopiedText] = useState<string | null>(null);

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedText(text);
      setTimeout(() => setCopiedText(null), 2000);
    } catch (err) {
      console.error("Failed to copy: ", err);
    }
  };

  const svc = services[name];
  if (!svc) return null;
  const statusText = statuses[name] || "Unknown";
  const isRunning = statusText.startsWith("Up") || statusText.startsWith("Running");
  const isHealthy = statusText.includes("(healthy)");
  const isToggling = statusText.startsWith("Toggling");
  
  const displayName = name
    .split(/[-_]/)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
    
  const description = SERVICE_DESCRIPTIONS[name] || "Stack Service";

  return (
    <Card className="flex flex-col border-[var(--border)] shadow-sm hover:shadow-md transition-shadow relative overflow-hidden">
      {isToggling && (
        <div className="absolute inset-0 z-10 bg-background/60 backdrop-blur-sm flex flex-col items-center justify-center">
          <Loader2 className="w-8 h-8 text-primary animate-spin mb-2" />
          <span className="text-sm font-bold text-foreground tracking-wide">Toggling...</span>
        </div>
      )}

      <CardHeader className="flex flex-row items-start justify-between space-y-0 pb-2">
        <div>
          <CardTitle className="text-xl font-bold tracking-tight">{displayName}</CardTitle>
          <CardDescription className="font-medium mt-1">
            <span className="capitalize">{svc.Group}</span> &middot; <span className="font-normal">{description}</span>
          </CardDescription>
        </div>
        <Badge
          variant={isRunning ? "default" : isToggling ? "secondary" : "outline"}
          className={
            isHealthy
              ? "bg-emerald-500 hover:bg-emerald-600 text-white shadow-sm border-0"
              : isRunning
              ? "bg-green-500 hover:bg-green-600 text-white shadow-sm border-0"
              : isToggling
              ? "bg-yellow-500 hover:bg-yellow-600 text-white shadow-sm border-0"
              : "text-muted-foreground shadow-sm"
          }
        >
          {isHealthy ? "Healthy" : isRunning ? "Running" : isToggling ? "Toggling" : "Stopped"}
        </Badge>
      </CardHeader>
      <CardContent className="flex-1 pt-4 pb-2">
        <div className="space-y-3 text-sm">
          {isRunning && name !== "caddy" && (
            <div className="p-3 bg-muted/30 rounded-lg space-y-2 border border-border/50">
              {svc.InternalPort ? (
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2 overflow-hidden">
                    <span className="font-semibold text-foreground shrink-0">URL:</span>
                    <span className="text-foreground font-mono text-sm truncate select-all">
                      https://{name}.localhost
                    </span>
                  </div>
                  <Button variant="ghost" size="icon" className="h-6 w-6 shrink-0 ml-2 cursor-pointer" onClick={() => copyToClipboard(`https://${name}.localhost`)}>
                    {copiedText === `https://${name}.localhost` ? <Check className="h-4 w-4 text-green-500" /> : <Copy className="h-3 w-3" />}
                  </Button>
                </div>
              ) : null}
              {(svc.InternalPort || DB_PORTS[name]) && (
                <div className="flex items-center justify-between mt-1">
                  <div className="flex items-center space-x-2">
                    <span className="font-semibold text-foreground shrink-0">Internal:</span>
                    <span className="text-foreground font-mono text-sm truncate select-all">{name}:{svc.InternalPort || DB_PORTS[name]}</span>
                  </div>
                  <Button variant="ghost" size="icon" className="h-6 w-6 shrink-0 ml-2 cursor-pointer" onClick={() => copyToClipboard(`${name}:${svc.InternalPort || DB_PORTS[name]}`)}>
                    {copiedText === `${name}:${svc.InternalPort || DB_PORTS[name]}` ? <Check className="h-4 w-4 text-green-500" /> : <Copy className="h-3 w-3" />}
                  </Button>
                </div>
              )}
            </div>
          )}
          {svc.DependsOn?.length > 0 && (
            <div className="px-1 text-xs text-muted-foreground mt-2">
              <span className="font-semibold">Depends on:</span> {svc.DependsOn.join(", ")}
            </div>
          )}
          <div className="px-1 text-xs font-mono text-muted-foreground h-4 mt-2">
             {statusText !== "Stopped" && !isRunning && !isToggling ? statusText : ""}
          </div>
        </div>
      </CardContent>
      <CardFooter className="flex justify-between items-center bg-muted/20 border-t py-3 mt-auto rounded-b-xl gap-2">
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => onOpenEnv(name)} className="shadow-sm cursor-pointer px-3">
            Config
          </Button>
          <Button variant="outline" size="sm" onClick={() => onOpenVolume(name)} className="shadow-sm cursor-pointer px-3">
            Storage
          </Button>
          {isRunning && name !== "caddy" && (
            <Button variant="outline" size="sm" onClick={() => onOpenRestart(name)} className="shadow-sm cursor-pointer px-3" disabled={isToggling}>
              <RefreshCw className="h-4 w-4" />
            </Button>
          )}
        </div>
        <div className="flex items-center space-x-3">
          <span className="text-sm font-semibold tracking-wide text-muted-foreground">
            {isRunning ? "ON" : "OFF"}
          </span>
          {name === "caddy" ? (
            <MockupSlider checked={true} disabled={true} onChange={() => {}} />
          ) : (
            <MockupSlider 
              checked={isRunning} 
              disabled={isToggling} 
              onChange={() => toggleService(name, isRunning)} 
            />
          )}
        </div>
      </CardFooter>
    </Card>
  );
}
