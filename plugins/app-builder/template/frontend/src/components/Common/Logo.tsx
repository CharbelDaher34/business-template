import { Link } from "@tanstack/react-router"
import { Boxes } from "lucide-react"

import { APP_NAME } from "@/config"
import { cn } from "@/lib/utils"

interface LogoProps {
  variant?: "full" | "icon" | "responsive"
  className?: string
  asLink?: boolean
}

export function Logo({
  variant = "full",
  className,
  asLink = true,
}: LogoProps) {
  const content = (
    <span
      className={cn("flex items-center gap-2 font-semibold text-lg", className)}
    >
      <Boxes className="size-[1.25em] shrink-0" aria-hidden />
      {variant !== "icon" && (
        <span
          className={cn(
            "truncate",
            variant === "responsive" && "group-data-[collapsible=icon]:hidden",
          )}
        >
          {APP_NAME}
        </span>
      )}
    </span>
  )

  if (!asLink) {
    return content
  }

  return <Link to="/">{content}</Link>
}
