"use client";

import { cn } from "@/lib/cn";
import { Card } from "@/components/ui/card";
import { Heading, Text } from "@/components/ui/typography";

export function PageHeader({
  kicker,
  title,
  description,
  actions,
  className,
}: {
  kicker: string;
  title: string;
  description?: string | null;
  actions?: React.ReactNode;
  className?: string;
}) {
  return (
    <Card className={cn("flex flex-col gap-4 md:flex-row md:items-start md:justify-between", className)}>
      <div className="min-w-0">
        <Text variant="kicker">{kicker}</Text>
        <Heading as="h1" size="h1" className="mt-2">
          {title}
        </Heading>
        {description ? (
          <Text variant="muted" className="mt-2 max-w-2xl">
            {description}
          </Text>
        ) : null}
      </div>
      {actions ? <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-center">{actions}</div> : null}
    </Card>
  );
}

