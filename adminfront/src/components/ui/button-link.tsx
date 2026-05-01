import Link from "next/link";
import { buttonClassName, type ButtonSize, type ButtonVariant } from "@/components/ui/button.styles";

export type ButtonLinkProps = React.ComponentProps<typeof Link> & {
  variant?: ButtonVariant;
  size?: ButtonSize;
};

export function ButtonLink({ variant = "secondary", size = "md", className, ...props }: ButtonLinkProps) {
  return <Link {...props} className={buttonClassName({ variant, size, className })} />;
}

