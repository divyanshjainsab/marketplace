import { redirect } from "next/navigation";

export default function LegacyOrgCatchAll({ params }: { params: { rest: string[] } }) {
  redirect(`/${params.rest.join("/")}`);
}

