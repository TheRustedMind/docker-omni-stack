import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Loader2 } from "lucide-react";

interface EnvConfigDialogProps {
  serviceName: string | null;
  isOpen: boolean;
  onClose: () => void;
}

export function EnvConfigDialog({ serviceName, isOpen, onClose }: EnvConfigDialogProps) {
  const [envContent, setEnvContent] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (isOpen && serviceName) {
      invoke("get_env_file", { service: serviceName })
        .then((content: any) => setEnvContent(content as string))
        .catch((e) => alert(`Operation failed: ${e}`));
    }
  }, [isOpen, serviceName]);

  const saveEnv = async () => {
    if (!serviceName) return;
    setSaving(true);
    try {
      await invoke("save_env_file", { service: serviceName, content: envContent });
      onClose();
    } catch (e) {
      console.error(e);
      alert("Failed to save .env file");
    } finally {
      setSaving(false);
    }
  };

  if (!isOpen || !serviceName) return null;

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[600px] border-border shadow-2xl">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold">Configure {serviceName}</DialogTitle>
          <DialogDescription>
            Edit the environment variables for this service.
          </DialogDescription>
        </DialogHeader>
        <div className="py-4">
          <Textarea
            value={envContent}
            onChange={(e) => setEnvContent(e.target.value)}
            className="font-mono text-sm min-h-[350px] bg-muted/30 focus-visible:ring-1"
            spellCheck="false"
          />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} className="cursor-pointer">
            Cancel
          </Button>
          <Button onClick={saveEnv} disabled={saving} className="font-semibold shadow-sm cursor-pointer">
            {saving ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
            {saving ? "Saving..." : "Save Config"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
