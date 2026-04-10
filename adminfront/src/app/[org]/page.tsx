import { redirect } from "next/navigation";

export default function OrgHomePage({ params }: { params: { org: string } }) {
  redirect(`/${params.org}/dashboard`);
}

