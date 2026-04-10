import { redirect } from "next/navigation";
import { getJwt } from "@/lib/auth";

export default function HomePage() {
  const jwt = getJwt();
  redirect(jwt ? "/dashboard" : "/login");
}
