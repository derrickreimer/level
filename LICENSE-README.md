# License README

Level is licensed as "source-available" software rather than "Open Source" (as defined by the Open Source Initiative).

The purpose of this document is to provide some rationale behind this decision and answer some common questions that may arise.

## A quick tour of licensing

There are several common licensing schemes (and accompanying business models) for software businesses:

- Closed-source and proprietary
- The "open core" model: an open-source core version with a dual-licensed proprietary offering (e.g., GitLab)
- Open source with a managed services component (e.g., Discourse and Ghost)
- Source-available (similar to "open source" but with some added restrictions, such as the Commons Clause)

A majority choose to adopt the closed-source, proprietary model. The calculus is pretty straightforward: the company funds the development of the product and retains all intellectual property rights to monetize it.

The open core and fully open source models open up more possibilities: people from the community can download and use it for free and can contribute their development efforts back to the project if they so choose. There are many officially "approved" open source licenses with varying properties that all adhere to [The Open Source Defintion](https://opensource.org/osd) defined by the Open Source Initiative. 

By and large, companies licensing their code as open source rely on selling hosting (or other managed services) to generate revenue. Additionally, most reserve their trademarks/copyrights to prevent a competing business from marketing their codebase under the same name (or something confusingly similar).

## Why source-available is right for Level

When I made the decision to build Level out in the open, I had several goals:

- Provide an example to the developer community of a full-scale SaaS application built with emerging technologies (Elixir, Elm, GraphQL, etc.)
- Allow people and businesses the ability to download the software for free and manage their own hosting
- Build a profitable little company to support the continued development of the product

The approved open source licenses do to nothing stop a larger company from forking the codebase, changing the name, and competing with my business using an identical offering. If Level lives up to my expectations, then it would only make rational sense for someone to seize upon that opportunity eventually. I had to ask myself, "Is that what I desire to happen?"

I believe the answer for most companies who open source their core product is "no."

There are some ways to disincentivize competition that I've observed:

- Dual-licensing the codebase and reserving the most valuable features for the proprietary version
- Intentionally making it harder to deploy the codebase (or keep that kind of code private altogether)
- Raising venture capital funding to level the playing field with other well-funded opportunists

None of these options align with my values and my vision for Level. Rather than adopting a 100% permissive license and attempting to play defense against rational actors, it makes the most sense for Level's licensing to align with my original goals fully.

## How the Commons Clause works

Level is licensed using a combination of the Apache 2.0 license and the [Commons Clause](https://commonsclause.com/), a new license condition drafted by Heather Meeker. The clause can be added to an existing open source license to disallow one particular right: the right to sell a product "whose value derives, entirely or substantially, from the functionality of the Software."

This means you can still:

- Host the software for your own personal and commercial use
- Fork the codebase and use it as the basis for a non-competing product or service
- Sell consulting services to help people host Level for their own use

But, you cannot do the following without permission:

- Sell a hosted (SaaS) version of Level
- Sell a downloadable version of Level

I genuinely believe this is the most reasonable and sustainable licensing scheme for Level moving forward.
