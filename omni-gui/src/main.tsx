import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";
import { StackProvider } from "./context/StackContext";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <StackProvider>
      <App />
    </StackProvider>
  </React.StrictMode>,
);
