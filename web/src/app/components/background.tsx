import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

/*
  Hintergrund-Wrapper nach dem Mainline-Template (shadcnblocks.com,
  MIT + Commons Clause): leichter Creme-Orange-Gradient (--tint)
  am oberen Rand, der nach weiß ausläuft — randfüllend, ohne
  abgerundete Ecken. Nur Design — der Wrapper enthält keinen
  eigenen Inhalt.
*/
type BackgroundProps = {
  children: ReactNode;
  variant?: "top" | "bottom";
  className?: string;
};

export const Background = ({
  children,
  variant = "top",
  className,
}: BackgroundProps) => {
  return (
    <div
      className={cn(
        "relative",
        variant === "top" &&
          "from-tint/50 via-background to-background/80 bg-linear-to-b via-20%",
        variant === "bottom" &&
          "from-background via-background to-tint/50 bg-linear-to-b",
        className,
      )}
    >
      {children}
    </div>
  );
};
