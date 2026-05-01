import { Card } from "@/components/ui/card";
import { ButtonLink } from "@/components/ui/button-link";
import { Heading, Text } from "@/components/ui/typography";

export default function NotAuthorizedPage() {
  return (
    <main className="mx-auto flex min-h-[70vh] max-w-lg flex-col items-center justify-center px-6 py-16 text-center">
      <Card className="w-full bg-white/80 backdrop-blur">
        <Text variant="kicker">Access denied</Text>
        <Heading as="h1" size="h2" className="mt-4 text-balance">
          Admin access is required
        </Heading>
        <Text variant="muted" className="mt-3">
          Your account does not have the roles needed to access the admin dashboard.
        </Text>
        <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:justify-center">
          <ButtonLink href="/login?manual=1" variant="primary">
            Sign in again
          </ButtonLink>
          <ButtonLink href="/" variant="secondary">
            Go home
          </ButtonLink>
        </div>
      </Card>
    </main>
  );
}
