<-- usage-rules-start -->
<-- igniter-start -->
## igniter usage
# Rules for working with Igniter

## Understanding Igniter

Igniter is a code generation and project patching framework that enables semantic manipulation of Elixir codebases. It provides tools for creating intelligent generators that can both create new files and modify existing ones safely. Igniter works with AST (Abstract Syntax Trees) through Sourceror.Zipper to make precise, context-aware changes to your code.

## Available Modules

### Project-Level Modules (`Igniter.Project.*`)

- **`Igniter.Project.Application`** - Working with Application modules and application configuration
- **`Igniter.Project.Config`** - Modifying Elixir config files (config.exs, runtime.exs, etc.)
- **`Igniter.Project.Deps`** - Managing dependencies declared in mix.exs
- **`Igniter.Project.Formatter`** - Interacting with .formatter.exs files
- **`Igniter.Project.IgniterConfig`** - Managing .igniter.exs configuration files
- **`Igniter.Project.MixProject`** - Updating project configuration in mix.exs
- **`Igniter.Project.Module`** - Creating and managing modules with proper file placement
- **`Igniter.Project.TaskAliases`** - Managing task aliases in mix.exs
- **`Igniter.Project.Test`** - Working with test and test support files

### Code-Level Modules (`Igniter.Code.*`)

- **`Igniter.Code.Common`** - General purpose utilities for working with Sourceror.Zipper
- **`Igniter.Code.Function`** - Working with function definitions and calls
- **`Igniter.Code.Keyword`** - Manipulating keyword lists
- **`Igniter.Code.List`** - Working with lists in AST
- **`Igniter.Code.Map`** - Manipulating maps
- **`Igniter.Code.Module`** - Working with module definitions and usage
- **`Igniter.Code.String`** - Utilities for string literals
- **`Igniter.Code.Tuple`** - Working with tuples

<-- igniter-end -->
<-- ash_graphql-start -->
## ash_graphql usage
# Rules for working with AshGraphql

## Understanding AshGraphql

AshGraphql is a package for integrating Ash Framework with GraphQL. It provides tools for generating GraphQL types, queries, mutations, and subscriptions from your Ash resources. AshGraphql leverages Absinthe under the hood to create a seamless integration between your Ash resources and GraphQL API.

## Domain Configuration

AshGraphql works by extending your Ash domains and resources with GraphQL capabilities. First, add the AshGraphql extension to your domain.

### Setting Up Your Domain

```elixir
defmodule MyApp.Blog do
  use Ash.Domain,
    extensions: [
      AshGraphql.Domain
    ]

  graphql do
    # Define GraphQL-specific settings for this domain
    authorize? true

    # Add GraphQL queries separate from the resource config
    queries do
      get Post, :get_post, :read
      list Post, :list_posts, :read
    end

    # Add GraphQL mutations separate from the resource config
    mutations do
      create Post, :create_post, :create
      update Post, :update_post, :update
      destroy Post, :destroy_post, :destroy
    end

    # Add GraphQL subscriptions
    subscriptions do
      subscribe Post, :post_created do
        action_types(:create)
      end
    end
  end

  resources do
    resource MyApp.Blog.Post
    resource MyApp.Blog.Comment
  end
end
```

### Creating Your GraphQL Schema

Create an Absinthe schema that uses your Ash domains:

```elixir
defmodule MyApp.Schema do
  use Absinthe.Schema

  # List all domains that contain resources to expose via GraphQL
  @domains [MyApp.Blog, MyApp.Accounts]

  # Configure AshGraphql with your domains
  use AshGraphql,
    domains: @domains,
    # Generate SDL file (optional)
    generate_sdl_file: "schema.graphql"
end
```

## Resource Configuration

Each resource that you want to expose via GraphQL needs to include the AshGraphql.Resource extension.

### Setting Up Resources

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    domain: MyApp.Blog,
    extensions: [AshGraphql.Resource]

  attributes do
    uuid_primary_key :id
    attribute :title, :string
    attribute :body, :string
    attribute :published, :boolean
    attribute :view_count, :integer
  end

  relationships do
    belongs_to :author, MyApp.Accounts.User
    has_many :comments, MyApp.Blog.Comment
  end

  graphql do
    # The GraphQL type name (required)
    type :post

    # Customize attribute types for GraphQL
    attribute_types view_count: :string

    # Configure managed relationships (for nested create/update)
    managed_relationships do
      managed_relationship :with_comments, :comments
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :list_published do
      filter expr(published == true)
    end

    update :publish do
      accept []
      change set_attribute(:published, true)
    end
  end
end
```

## Custom Types

AshGraphql automatically handles conversion of Ash types to GraphQL types, but you can customize it:

```elixir
defmodule MyApp.CustomType do
  use Ash.Type

  @impl true
  def graphql_type(_), do: :string

  @impl true
  def graphql_input_type(_), do: :string
end
```

<-- ash_graphql-end -->
<-- ash_authentication-start -->
## ash_authentication usage
# AshAuthentication Usage Rules

## Core Concepts
- **Strategies**: password, OAuth2, magic_link, api_key authentication methods
- **Tokens**: JWT for stateless authentication
- **UserIdentity**: links users to OAuth2 providers
- **Add-ons**: confirmation, logout-everywhere functionality
- **Actions**: auto-generated by strategies (register, sign_in, etc.), can be overridden on the resource

## Key Principles
- Always use secrets management - never hardcode credentials
- Enable tokens for magic_link, confirmation, OAuth2
- UserIdentity resource optional for OAuth2 (required for multiple providers per user)
- API keys require strict policy controls and expiration management
- Use prefixes for API keys to enable secret scanning compliance
- Check existing strategies: `AshAuthentication.Info.strategies/1`

## Strategy Selection

**Password** - Email/password authentication
- Requires: `:email`, `:hashed_password` attributes, unique identity

**Magic Link** - Passwordless email authentication
- Requires: `:email` attribute, sender implementation, tokens enabled

**API Key** - Token-based authentication for APIs
- Requires: API key resource, relationship to user, sign-in action

**OAuth2** - Social/enterprise login (GitHub, Google, Auth0, Apple, OIDC, Slack)
- Requires: custom actions, secrets
- Optional: UserIdentity resource (for multiple providers per user)

## Password Strategy

```elixir
authentication do
  strategies do
    password :password do
      identity_field :email
      hashed_password_field :hashed_password
      resettable do
        sender MyApp.PasswordResetSender
      end
    end
  end
end

# Required attributes:
attributes do
  attribute :email, :ci_string, allow_nil?: false, public?: true
  attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
end

identities do
  identity :unique_email, [:email]
end
```

## Magic Link Strategy

```elixir
authentication do
  strategies do
    magic_link do
      identity_field :email
      sender MyApp.MagicLinkSender
    end
  end
end

# Sender implementation required:
defmodule MyApp.MagicLinkSender do
  use AshAuthentication.Sender

  def send(user_or_email, token, _opts) do
    MyApp.Emails.deliver_magic_link(user_or_email, token)
  end
end
```

## API Key Strategy

```elixir
# 1. Create API key resource
defmodule MyApp.Accounts.ApiKey do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:user_id, :expires_at]
      change {AshAuthentication.Strategy.ApiKey.GenerateApiKey, prefix: :myapp, hash: :api_key_hash}
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :api_key_hash, :binary, allow_nil?: false, sensitive?: true
    attribute :expires_at, :utc_datetime_usec, allow_nil?: false
  end

  relationships do
    belongs_to :user, MyApp.Accounts.User, allow_nil?: false
  end

  calculations do
    calculate :valid, :boolean, expr(expires_at > now())
  end

  identities do
    identity :unique_api_key, [:api_key_hash]
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end
end

# 2. Add strategy to user resource
authentication do
  strategies do
    api_key do
      api_key_relationship :valid_api_keys
      api_key_hash_attribute :api_key_hash
    end
  end
end

# 3. Add relationship to user
relationships do
  has_many :valid_api_keys, MyApp.Accounts.ApiKey do
    filter expr(valid)
  end
end

# 4. Add sign-in action to user
actions do
  read :sign_in_with_api_key do
    argument :api_key, :string, allow_nil?: false
    prepare AshAuthentication.Strategy.ApiKey.SignInPreparation
  end
end
```

**Security considerations:**
- API keys are hashed for storage security
- Use policies to restrict API key access to specific actions
- Check `user.__metadata__[:using_api_key?]` to detect API key authentication
- Access the API key via `user.__metadata__[:api_key]` for permission checks

## OAuth2 Strategies

**Supported providers:** github, google, auth0, apple, oidc, slack

**Required for all OAuth2:**
- Custom `register_with_[provider]` action
- Secrets management
- Tokens enabled

**Optional for all OAuth2:**
- UserIdentity resource (for multiple providers per user)

### OAuth2 Configuration Pattern
```elixir
# Strategy configuration
authentication do
  strategies do
    github do  # or google, auth0, apple, oidc, slack
      client_id MyApp.Secrets
      client_secret MyApp.Secrets
      redirect_uri MyApp.Secrets
      # auth0 also needs: base_url
      # apple also needs: team_id, private_key_id, private_key_path
      # oidc also needs: openid_configuration_uri
      identity_resource MyApp.Accounts.UserIdentity
    end
  end
end

# Required action (replace 'github' with provider name)
actions do
  create :register_with_github do
    argument :user_info, :map, allow_nil?: false
    argument :oauth_tokens, :map, allow_nil?: false
    upsert? true
    upsert_identity :unique_email

    change AshAuthentication.GenerateTokenChange
    
    # If UserIdentity resource is being used
    change AshAuthentication.Strategy.OAuth2.IdentityChange

    change fn changeset, _ctx ->
      user_info = Ash.Changeset.get_argument(changeset, :user_info)
      Ash.Changeset.change_attributes(changeset, Map.take(user_info, ["email"]))
    end
  end
end
```

## Add-ons

### Confirmation
```elixir
authentication do
  tokens do
    enabled? true
    token_resource MyApp.Accounts.Token
  end

  add_ons do
    confirmation :confirm do
      monitor_fields [:email]
      sender MyApp.ConfirmationSender
    end
  end
end
```

### Log Out Everywhere
```elixir
authentication do
  tokens do
    store_all_tokens? true
  end

  add_ons do
    log_out_everywhere do
      apply_on_password_change? true
    end
  end
end
```

## Working with Authentication

### Strategy Protocol
```elixir
# Get and use strategies
strategy = AshAuthentication.Info.strategy!(MyApp.User, :password)
{:ok, user} = AshAuthentication.Strategy.action(strategy, :sign_in, params)

# List strategies
strategies = AshAuthentication.Info.strategies(MyApp.User)
```

### Token Operations
```elixir
# User/subject conversion
subject = AshAuthentication.user_to_subject(user)
{:ok, user} = AshAuthentication.subject_to_user(subject, MyApp.User)

# Token management
AshAuthentication.TokenResource.revoke(MyApp.Token, token)
```

### Policies
```elixir
policies do
  bypass AshAuthentication.Checks.AshAuthenticationInteraction do
    authorize_if always()
  end
end
```

## Common Implementation Patterns

### Pattern: Multiple Authentication Methods
When users need multiple ways to authenticate:

```elixir
authentication do
  tokens do
    enabled? true
    token_resource MyApp.Accounts.Token
  end

  strategies do
    password :password do
      identity_field :email
      hashed_password_field :hashed_password
    end

    github do
      client_id MyApp.Secrets
      client_secret MyApp.Secrets
      redirect_uri MyApp.Secrets
      identity_resource MyApp.Accounts.UserIdentity
    end

    magic_link do
      identity_field :email
      sender MyApp.MagicLinkSender
    end
  end
end
```

### Pattern: OAuth2 with User Registration
When new users can register via OAuth2:

```elixir
actions do
  create :register_with_github do
    argument :user_info, :map, allow_nil?: false
    argument :oauth_tokens, :map, allow_nil?: false
    upsert? true
    upsert_identity :email

    change AshAuthentication.GenerateTokenChange
    change fn changeset, _ctx ->
      user_info = Ash.Changeset.get_argument(changeset, :user_info)

      changeset
      |> Ash.Changeset.change_attribute(:email, user_info["email"])
      |> Ash.Changeset.change_attribute(:name, user_info["name"])
    end
  end
end
```

### Pattern: Custom Token Configuration
When you need specific token behavior:

```elixir
authentication do
  tokens do
    enabled? true
    token_resource MyApp.Accounts.Token
    signing_secret MyApp.Secrets
    token_lifetime {24, :hours}
    store_all_tokens? true  # For logout-everywhere functionality
    require_token_presence_for_authentication? false
  end
end
```

## Customizing Authentication Actions

When customizing generated authentication actions (register, sign_in, etc.):

**Key Security Rules:**
- Always mark credentials with `sensitive?: true` (passwords, API keys, tokens)
- Use `public?: false` for internal fields and highly sensitive PII
- Use `public?: true` for identity fields and UI display data
- Include required authentication changes (`GenerateTokenChange`, `HashPasswordChange`, etc.)

**Argument Handling:**
- All arguments must be used in `accept` or `change set_attribute()`
- Use `allow_nil?: false` for required arguments
- OAuth2 data must be extracted in changes, not accepted directly

**Example Custom Registration:**
```elixir
create :register_with_password do
  argument :password, :string, allow_nil?: false, sensitive?: true
  argument :first_name, :string, allow_nil?: false
  
  accept [:email, :first_name]
  
  change AshAuthentication.GenerateTokenChange
  change AshAuthentication.Strategy.Password.HashPasswordChange
end
```

For more guidance, see the "Customizing Authentication Actions" section in the getting started guide.
<-- ash_authentication-end -->
<-- ash_phoenix-start -->
## ash_phoenix usage
# Rules for working with AshPhoenix

## Understanding AshPhoenix

AshPhoenix is a package for integrating Ash Framework with Phoenix Framework. It provides tools for integrating with Phoenix forms (`AshPhoenix.Form`), Phoenix LiveViews (`AshPhoenix.LiveView`), and more. AshPhoenix makes it seamless to use Phoenix's powerful UI capabilities with Ash's data management features.

## Form Integration

AshPhoenix provides `AshPhoenix.Form`, a powerful module for creating and handling forms backed by Ash resources.

### Creating Forms

```elixir
# For creating a new resource
form = AshPhoenix.Form.for_create(MyApp.Blog.Post, :create)

# For updating an existing resource
post = MyApp.Blog.get_post!(post_id)
form = AshPhoenix.Form.for_update(post, :update)

# Form with initial value
form = AshPhoenix.Form.for_create(MyApp.Blog.Post, :create,
  params: %{title: "Draft Title"}
)
```

### Code Interfaces

Using the `AshPhoenix` extension in domains gets you special functions in a resource's
code interface called `form_to_*`. Use this whenever possible.

First, add the `AshPhoenix` extension to our domains and resources, like so:

```elixir
use Ash.Domain,
  extensions: [AshPhoenix]
```

which will cause another function to be generated for each definition, beginning with `form_to_`.

For example, if you had the following,
```elixir
# in MyApp.Accounts
resources do
  resource MyApp.Accounts.User do
    define :register_with_password, args: [:email, :password]
  end
end
```

you could then make a form with:

```elixir
MyApp.Accounts.register_with_password(...opts)
```

By default, the `args` option in `define` is ignored when building forms. If you want to have positional arguments, configure that in the `forms` section which is added by the `AshPhoenix` section. For example:

```elixir
forms do
  form :register_with_password, args: [:email]
end
```

Which could then be used as:

```elixir
MyApp.Accounts.register_with_password(email, ...)
```

These positional arguments are *very important* for certain cases, because there may be values you do not want the form to be able to set. For example, when updating a user's settings, maybe the action takes a `user_id`, but the form is on a page for a specific user's id and so this should therefore not be editable in the form. Use positional arguments for this.

### Handling Form Submission

In your LiveView:

```elixir
def handle_event("validate", %{"form" => params}, socket) do
  form = AshPhoenix.Form.validate(socket.assigns.form, params)
  {:noreply, assign(socket, :form, form)}
end

def handle_event("submit", %{"form" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
    {:ok, post} ->
      socket =
        socket
        |> put_flash(:info, "Post created successfully")
        |> push_navigate(to: ~p"/posts/#{post.id}")
      {:noreply, socket}

    {:error, form} ->
      {:noreply, assign(socket, :form, form)}
  end
end
```

## Nested Forms

AshPhoenix supports forms with nested relationships, such as creating or updating related resources in a single form.

### Automatically Inferred Nested Forms

If your action has `manage_relationship`, AshPhoenix automatically infers nested forms:

```elixir
# In your resource:
create :create do
  accept [:name]
  argument :locations, {:array, :map}
  change manage_relationship(:locations, type: :create)
end

# In your template:
<.simple_form for={@form} phx-change="validate" phx-submit="submit">
  <.input field={@form[:name]} />

  <.inputs_for :let={location} field={@form[:locations]}>
    <.input field={location[:name]} />
  </.inputs_for>
</.simple_form>
```

### Adding and Removing Nested Forms

To add a nested form with a button:

```heex
<.button type="button" phx-click="add-form" phx-value-path={@form.name <> "[locations]"}>
  <.icon name="hero-plus" />
</.button>
```

In your LiveView:

```elixir
def handle_event("add-form", %{"path" => path}, socket) do
  form = AshPhoenix.Form.add_form(socket.assigns.form, path)
  {:noreply, assign(socket, :form, form)}
end
```

To remove a nested form:

```heex
<.button type="button" phx-click="remove-form" phx-value-path={location.name}>
  <.icon name="hero-x-mark" />
</.button>
```

```elixir
def handle_event("remove-form", %{"path" => path}, socket) do
  form = AshPhoenix.Form.remove_form(socket.assigns.form, path)
  {:noreply, assign(socket, :form, form)}
end
```

## Union Forms

AshPhoenix supports forms for union types, allowing different inputs based on the selected type.

```heex
<.inputs_for :let={fc} field={@form[:content]}>
  <.input
    field={fc[:_union_type]}
    phx-change="type-changed"
    type="select"
    options={[Normal: "normal", Special: "special"]}
  />

  <%= case fc.params["_union_type"] do %>
    <% "normal" -> %>
      <.input type="text" field={fc[:body]} />
    <% "special" -> %>
      <.input type="text" field={fc[:text]} />
  <% end %>
</.inputs_for>
```

In your LiveView:

```elixir
def handle_event("type-changed", %{"_target" => path} = params, socket) do
  new_type = get_in(params, path)
  path = :lists.droplast(path)

  form =
    socket.assigns.form
    |> AshPhoenix.Form.remove_form(path)
    |> AshPhoenix.Form.add_form(path, params: %{"_union_type" => new_type})

  {:noreply, assign(socket, :form, form)}
end
```

## Error Handling

AshPhoenix provides helpful error handling mechanisms:

```elixir
# In your LiveView
def handle_event("submit", %{"form" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
    {:ok, post} ->
      # Success path
      {:noreply, success_path(socket, post)}

    {:error, form} ->
      # Show validation errors
      {:noreply, assign(socket, form: form)}
  end
end
```

## Best Practices

1. **Let the Resource guide the UI**: Your Ash resource configuration determines a lot about how forms and inputs will work. Well-defined resources with appropriate validations and changes make AshPhoenix more effective.

2. **Leverage code interfaces**: Define code interfaces on your domains for a clean and consistent API to call your resource actions.

3. **Update resources before editing**: When building forms for updating resources, load the resource with all required relationships using `Ash.load!/2` before creating the form.

<-- ash_phoenix-end -->
<-- ash_oban-start -->
## ash_oban usage
# Rules for working with AshOban

## Understanding AshOban

AshOban is a package that integrates the Ash Framework with Oban, a robust job processing system for Elixir. It enables you to define triggers that can execute background jobs based on specific conditions in your Ash resources, as well as schedule periodic actions. AshOban is particularly useful for handling asynchronous tasks, background processing, and scheduled operations in your Ash application.

## Setting Up AshOban

To use AshOban with an Ash resource, add AshOban to the extensions list:

```elixir
use Ash.Resource,
  extensions: [AshOban]
```

## Defining Triggers

Triggers are the primary way to define background jobs in AshOban. They can be configured to run when certain conditions are met on your resources. They work
by running a scheduler job on the given cron job.

### Basic Trigger

```elixir
oban do
  triggers do
    trigger :process do
      action :process
      scheduler_cron "*/5 * * * *"
      where expr(processed != true)
      worker_read_action :read
      worker_module_name MyApp.Workers.Process
      scheduler_module_name MyApp.Schedulers.Process
    end
  end
end
```

### Trigger Configuration Options

- `action` - The action to be triggered (required)
- `where` - The filter expression to determine if something should be triggered
- `worker_read_action` - The read action to use when fetching individual records
- `read_action` - The read action to use when querying records (must support keyset pagination)
- `worker_module_name` - The module name for the generated worker (important for job stability)
- `scheduler_module_name` - The module name for the generated scheduler
- `max_attempts` - How many times to attempt the job (default: 1)
- `queue` - The queue to place the worker job in (defaults to trigger name)
- `trigger_once?` - Ensures that jobs that complete quickly aren't rescheduled (default: false)

## Scheduled Actions

Scheduled actions allow you to run periodic tasks according to a cron schedule:

```elixir
oban do
  scheduled_actions do
    schedule :daily_report, "0 8 * * *" do
      action :generate_report
      worker_module_name MyApp.Workers.DailyReport
    end
  end
end
```

### Scheduled Action Configuration Options

- `cron` - The schedule in crontab notation
- `action` - The generic or create action to call when the schedule is triggered
- `action_input` - Inputs to supply to the action when it is called
- `worker_module_name` - The module name for the generated worker
- `queue` - The queue to place the job in
- `max_attempts` - How many times to attempt the job (default: 1)

## Triggering Jobs Programmatically

You can trigger jobs programmatically using `run_oban_trigger` in your actions:

```elixir
update :process_item do
  accept [:item_id]
  change set_attribute(:processing, true)
  change run_oban_trigger(:process_data)
end
```

Or directly using the AshOban API:

```elixir
# Run a trigger for a specific record
AshOban.run_trigger(record, :process_data)

# Run a trigger for multiple records
AshOban.run_triggers(records, :process_data)

# Schedule a trigger or scheduled action
AshOban.schedule(MyApp.Resource, :process_data, actor: current_user)
```

## Working with Actors

AshOban can persist the actor that triggered a job, making it available when the job runs:

### Setting up Actor Persistence

```elixir
# Define an actor persister module
defmodule MyApp.ObanActorPersister do
  @behaviour AshOban.PersistActor

  @impl true
  def store(actor) do
    # Convert actor to a format that can be stored in JSON
    Jason.encode!(actor)
  end

  @impl true
  def lookup(actor_json) do
    # Convert the stored JSON back to an actor
    case Jason.decode(actor_json) do
      {:ok, data} -> {:ok, MyApp.Accounts.get_user!(data["id"])}
      error -> error
    end
  end
end

# Configure it
config :ash_oban, :actor_persister, MyApp.ObanActorPersister
```

### Using Actor in Triggers

```elixir
# Specify actor_persister for a specific trigger
trigger :process do
  action :process
  actor_persister MyApp.ObanActorPersister
end

# Pass the actor when triggering a job
AshOban.run_trigger(record, :process, actor: current_user)
```

## Multi-tenancy Support

AshOban supports multi-tenancy in your Ash application:

```elixir
oban do
  # Global tenant configuration
  list_tenants [1, 2, 3]  # or a function that returns tenants

  triggers do
    trigger :process do
      # Override tenants for a specific trigger
      list_tenants fn -> [2] end
      action :process
    end
  end
end
```

## Debugging and Error Handling

AshOban provides options for debugging and handling errors:

```elixir
trigger :process do
  action :process
  # Enable detailed debug logging for this trigger
  debug? true

  # Configure error handling
  log_errors? true
  log_final_error? true

  # Define an action to call after the last attempt has failed
  on_error :mark_failed
end
```

You can also enable global debug logging:

```elixir
config :ash_oban, :debug_all_triggers?, true
```

## Best Practices

1. **Always define module names** - Use explicit `worker_module_name` and `scheduler_module_name` to prevent issues when refactoring.

2. **Use meaningful trigger names** - Choose clear, descriptive names for your triggers that reflect their purpose.

3. **Handle errors gracefully** - Use the `on_error` option to define how to handle records that fail processing repeatedly.

4. **Use appropriate queues** - Organize your jobs into different queues based on priority and resource requirements.

5. **Optimize read actions** - Ensure that read actions used in triggers support keyset pagination for efficient processing.

6. **Design for idempotency** - Jobs should be designed to be safely retried without causing data inconsistencies.

<-- ash_oban-end -->
<-- ash_postgres-start -->
## ash_postgres usage
# Rules for working with AshPostgres

## Understanding AshPostgres

AshPostgres is the PostgreSQL data layer for Ash Framework. It's the most fully-featured Ash data layer and should be your default choice unless you have specific requirements for another data layer. Any PostgreSQL version higher than 13 is fully supported.

## Basic Configuration

To use AshPostgres, add the data layer to your resource:

```elixir
defmodule MyApp.Tweet do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    integer_primary_key :id
    attribute :text, :string
  end

  relationships do
    belongs_to :author, MyApp.User
  end

  postgres do
    table "tweets"
    repo MyApp.Repo
  end
end
```

## PostgreSQL Configuration

### Table & Schema Configuration

```elixir
postgres do
  # Required: Define the table name for this resource
  table "users"

  # Optional: Define the PostgreSQL schema
  schema "public"

  # Required: Define the Ecto repo to use
  repo MyApp.Repo

  # Optional: Control whether migrations are generated for this resource
  migrate? true
end
```

## Foreign Key References

Use the `references` section to configure foreign key behavior:

```elixir
postgres do
  table "comments"
  repo MyApp.Repo

  references do
    # Simple reference with defaults
    reference :post

    # Fully configured reference
    reference :user,
      on_delete: :delete,      # What happens when referenced row is deleted
      on_update: :update,      # What happens when referenced row is updated
      name: "comments_to_users_fkey", # Custom constraint name
      deferrable: true,        # Make constraint deferrable
      initially_deferred: false # Defer constraint check to end of transaction
  end
end
```

### Foreign Key Actions

For `on_delete` and `on_update` options:

- `:nothing` or `:restrict` - Prevent the change to the referenced row
- `:delete` - Delete the row when the referenced row is deleted (for `on_delete` only)
- `:update` - Update the row according to changes in the referenced row (for `on_update` only)
- `:nilify` - Set all foreign key columns to NULL
- `{:nilify, columns}` - Set specific columns to NULL (Postgres 15.0+ only)

> **Warning**: These operations happen directly at the database level. No resource logic, authorization rules, validations, or notifications are triggered.

## Check Constraints

Define database check constraints:

```elixir
postgres do
  check_constraints do
    check_constraint :positive_amount,
      check: "amount > 0",
      name: "positive_amount_check",
      message: "Amount must be positive"

    check_constraint :status_valid,
      check: "status IN ('pending', 'active', 'completed')"
  end
end
```

## Custom Indexes

Define custom indexes beyond those automatically created for identities and relationships:

```elixir
postgres do
  custom_indexes do
    index [:first_name, :last_name]

    index :email,
      unique: true,
      name: "users_email_index",
      where: "email IS NOT NULL",
      using: :gin

    index [:status, :created_at],
      concurrently: true,
      include: [:user_id]
  end
end
```

## Custom SQL Statements

Include custom SQL in migrations:

```elixir
postgres do
  custom_statements do
    statement "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""

    statement """
    CREATE TRIGGER update_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();
    """

    statement "DROP INDEX IF EXISTS posts_title_index",
      on_destroy: true # Only run when resource is destroyed/dropped
  end
end
```

## Migrations and Codegen

### Development Migration Workflow (Recommended)

For development iterations, use the dev workflow to avoid naming migrations prematurely:

1. Make resource changes
2. Run `mix ash.codegen --dev` to generate and run dev migrations
3. Review the migrations and run `mix ash.migrate` to run them
4. Continue making changes and running `mix ash.codegen --dev` as needed
5. When your feature is complete, run `mix ash.codegen add_feature_name` to generate final named migrations (this will rollback dev migrations and squash them)
3. Review the migrations and run `mix ash.migrate` to run them

### Traditional Migration Generation

For single-step changes or when you know the final feature name:

1. Run `mix ash.codegen add_feature_name` to generate migrations
2. Review the generated migrations in `priv/repo/migrations`
3. Run `mix ash.migrate` to apply the migrations

> **Tip**: The dev workflow (`--dev` flag) is preferred during development as it allows you to iterate without thinking of migration names and provides better development ergonomics.

> **Warning**: Always review migrations before applying them to ensure they are correct and safe.

## Multitenancy

AshPostgres supports schema-based multitenancy:

```elixir
defmodule MyApp.Tenant do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  # Resource definition...

  postgres do
    table "tenants"
    repo MyApp.Repo

    # Automatically create/manage tenant schemas
    manage_tenant do
      template ["tenant_", :id]
    end
  end
end
```

### Setting Up Multitenancy

1. Configure your repo to support multitenancy:

```elixir
defmodule MyApp.Repo do
  use AshPostgres.Repo, otp_app: :my_app

  # Return all tenant schemas for migrations
  def all_tenants do
    import Ecto.Query, only: [from: 2]
    all(from(t in "tenants", select: fragment("? || ?", "tenant_", t.id)))
  end
end
```

2. Mark resources that should be multi-tenant:

```elixir
defmodule MyApp.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  multitenancy do
    strategy :context
    attribute :tenant
  end

  # Resource definition...
end
```

3. When tenant migrations are generated, they'll be in `priv/repo/tenant_migrations`

4. Run tenant migrations in addition to regular migrations:

```bash
# Run regular migrations
mix ash.migrate

# Run tenant migrations
mix ash_postgres.migrate --tenants
```

## Advanced Features

### Manual Relationships

For complex relationships that can't be expressed with standard relationship types:

```elixir
defmodule MyApp.Post.Relationships.HighlyRatedComments do
  use Ash.Resource.ManualRelationship
  use AshPostgres.ManualRelationship

  def load(posts, _opts, context) do
    post_ids = Enum.map(posts, & &1.id)

    {:ok,
     MyApp.Comment
     |> Ash.Query.filter(post_id in ^post_ids)
     |> Ash.Query.filter(rating > 4)
     |> MyApp.read!()
     |> Enum.group_by(& &1.post_id)}
  end

  def ash_postgres_join(query, _opts, current_binding, as_binding, :inner, destination_query) do
    {:ok,
     Ecto.Query.from(_ in query,
       join: dest in ^destination_query,
       as: ^as_binding,
       on: dest.post_id == as(^current_binding).id,
       on: dest.rating > 4
     )}
  end

  # Other required callbacks...
end

# In your resource:
relationships do
  has_many :highly_rated_comments, MyApp.Comment do
    manual MyApp.Post.Relationships.HighlyRatedComments
  end
end
```

### Using Multiple Repos (Read Replicas)

Configure different repos for reads vs mutations:

```elixir
postgres do
  repo fn resource, type ->
    case type do
      :read -> MyApp.ReadReplicaRepo
      :mutate -> MyApp.WriteRepo
    end
  end
end
```

## Best Practices

1. **Organize migrations**: Run `mix ash.codegen` after each meaningful set of resource changes with a descriptive name:
   ```bash
   mix ash.codegen --name add_user_roles
   mix ash.codegen --name implement_post_tagging
   ```

2. **Use check constraints for domain invariants**: Enforce data integrity at the database level:
   ```elixir
   check_constraints do
     check_constraint :valid_status, check: "status IN ('pending', 'active', 'completed')"
     check_constraint :positive_balance, check: "balance >= 0"
   end
   ```

3. **Use custom statements for schema-only changes**: If you need to add database objects not directly tied to resources:
   ```elixir
   custom_statements do
     statement "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\""
     statement "CREATE INDEX users_search_idx ON users USING gin(search_vector)"
   end
   ```

Remember that using AshPostgres provides a full-featured PostgreSQL data layer for your Ash application, giving you both the structure and declarative approach of Ash along with the power and flexibility of PostgreSQL.

<-- ash_postgres-end -->
<-- ash_json_api-start -->
## ash_json_api usage
# Rules for working with AshJsonApi

## Understanding AshJsonApi

AshJsonApi is a package for integrating Ash Framework with the JSON:API specification. It provides tools for generating JSON:API compliant endpoints from your Ash resources. AshJsonApi allows you to expose your Ash resources through a standardized RESTful API, supporting all JSON:API features like filtering, sorting, pagination, includes, and relationships.

## Domain Configuration

AshJsonApi works by extending your Ash domains and resources with JSON:API capabilities. First, add the AshJsonApi extension to your domain.

### Setting Up Your Domain

```elixir
defmodule MyApp.Blog do
  use Ash.Domain,
    extensions: [
      AshJsonApi.Domain
    ]

  json_api do
    # Define JSON:API-specific settings for this domain
    authorize? true

    # You can define routes at the domain level
    routes do
      base_route "/posts", MyApp.Blog.Post do
        get :read
        index :read
        post :create
        patch :update
        delete :destroy
      end
    end
  end

  resources do
    resource MyApp.Blog.Post
    resource MyApp.Blog.Comment
  end
end
```

## Resource Configuration

Each resource that you want to expose via JSON:API needs to include the AshJsonApi.Resource extension.

### Setting Up Resources

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    domain: MyApp.Blog,
    extensions: [AshJsonApi.Resource]

  attributes do
    uuid_primary_key :id
    attribute :title, :string
    attribute :body, :string
    attribute :published, :boolean
  end

  relationships do
    belongs_to :author, MyApp.Accounts.User
    has_many :comments, MyApp.Blog.Comment
  end

  json_api do
    # The JSON:API type name (required)
    type "post"
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :list_published do
      filter expr(published == true)
    end

    update :publish do
      accept []
      change set_attribute(:published, true)
    end
  end
end
```

## Route Types

AshJsonApi supports various route types according to the JSON:API spec:

- `get` - Fetch a single resource by ID
- `index` - List resources, with support for filtering, sorting, and pagination
- `post` - Create a new resource
- `patch` - Update an existing resource
- `delete` - Destroy an existing resource
- `related` - Fetch related resources (e.g., `/posts/123/comments`)
- `relationship` - Fetch relationship data (e.g., `/posts/123/relationships/comments`)
- `post_to_relationship` - Add to a relationship
- `patch_relationship` - Replace a relationship
- `delete_from_relationship` - Remove from a relationship

## JSON:API Pagination, Filtering, and Sorting

AshJsonApi supports standard JSON:API query parameters:

- Filter: `?filter[attribute]=value`
- Sort: `?sort=attribute,-other_attribute` (descending with `-`)
- Pagination: `?page[number]=2&page[size]=10`
- Includes: `?include=author,comments.author`

<-- ash_json_api-end -->
<-- ash_ai-start -->
## ash_ai usage
# Rules for working with Ash AI

## Understanding Ash AI

Ash AI is an extension for the Ash framework that integrates AI capabilities with Ash resources. It provides tools for vectorization, embedding generation, LLM interaction, and tooling for AI models.

## Core Concepts

- **Vectorization**: Convert text attributes into vector embeddings for semantic search
- **AI Tools**: Expose Ash actions as tools for LLMs
- **Prompt-backed Actions**: Create actions where the implementation is handled by an LLM
- **MCP Server**: Expose your tools to Machine Context Protocol clients

## Vectorization

Vectorization allows you to convert text data into embeddings that can be used for semantic search.

### Setting Up Vectorization

Add vectorization to a resource by including the `AshAi` extension and defining a vectorize block:

```elixir
defmodule MyApp.Artist do
  use Ash.Resource, extensions: [AshAi]

  vectorize do
    # For creating a single vector from multiple attributes
    full_text do
      text(fn record ->
        """
        Name: #{record.name}
        Biography: #{record.biography}
        """
      end)

      # Optional - only rebuild embeddings when these attributes change
      used_attributes [:name, :biography]
    end

    # Choose a strategy for updating embeddings
    strategy :ash_oban

    # Specify your embedding model implementation
    embedding_model MyApp.OpenAiEmbeddingModel
  end

  # Rest of resource definition...
end
```

### Embedding Models

Create a module that implements the `AshAi.EmbeddingModel` behaviour to generate embeddings:

```elixir
defmodule MyApp.OpenAiEmbeddingModel do
  use AshAi.EmbeddingModel

  @impl true
  def dimensions(_opts), do: 3072

  @impl true
  def generate(texts, _opts) do
    api_key = System.fetch_env!("OPEN_AI_API_KEY")

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      "input" => texts,
      "model" => "text-embedding-3-large"
    }

    response =
      Req.post!("https://api.openai.com/v1/embeddings",
        json: body,
        headers: headers
      )

    case response.status do
      200 ->
        response.body["data"]
        |> Enum.map(fn %{"embedding" => embedding} -> embedding end)
        |> then(&{:ok, &1})

      _status ->
        {:error, response.body}
    end
  end
end
```

### Vectorization Strategies

Choose the appropriate strategy based on your performance requirements:

1. **`:after_action`** (default): Updates embeddings synchronously after each create and update action
   - Simple but can make your app slow
   - Not recommended for production use with many records

2. **`:ash_oban`**: Updates embeddings asynchronously using Ash Oban
   - Requires `ash_oban` extension
   - Better for production use

3. **`:manual`**: No automatic updates; you control when embeddings are updated
   - Most flexible but requires you to manage when to update embeddings

### Using the Vectors for Search

Use vector expressions in filters and sorts:

```elixir
read :semantic_search do
  argument :query, :string, allow_nil?: false

  prepare before_action(fn query, context ->
    case MyApp.OpenAiEmbeddingModel.generate([query.arguments.query], []) do
      {:ok, [search_vector]} ->
        Ash.Query.filter(
          query,
          vector_cosine_distance(full_text_vector, ^search_vector) < 0.5
        )
        |> Ash.Query.sort(asc: vector_cosine_distance(full_text_vector, ^search_vector))

      {:error, error} ->
        {:error, error}
    end
  end)
end
```

### Authorization for Vectorization

If you're using policies, add a bypass to allow embedding updates:

```elixir
bypass action(:ash_ai_update_embeddings) do
  authorize_if AshAi.Checks.ActorIsAshAi
end
```

## AI Tools

Expose your Ash actions as tools for LLMs to use by configuring them in your domain:

```elixir
defmodule MyApp.Blog do
  use Ash.Domain, extensions: [AshAi]

  tools do
    tool :read_posts, MyApp.Blog.Post, :read do
      description "customize the tool description"
    end
    tool :create_post, MyApp.Blog.Post, :create
    tool :publish_post, MyApp.Blog.Post, :publish
    tool :read_comments, MyApp.Blog.Comment, :read
  end

  # Rest of domain definition...
end
```

### Using Tools in LangChain

Add your Ash AI tools to a LangChain chain:

```elixir
chain =
  %{
    llm: LangChain.ChatModels.ChatOpenAI.new!(%{model: "gpt-4o"}),
    verbose: true
  }
  |> LangChain.Chains.LLMChain.new!()
  |> AshAi.setup_ash_ai(otp_app: :my_app, tools: [:list, :of, :tools])
```

## Structured Outputs (Prompt-Backed Actions)

Create actions that use LLMs for their implementation:

```elixir
action :analyze_sentiment, :atom do
  constraints one_of: [:positive, :negative]

  description """
  Analyzes the sentiment of a given piece of text to determine if it is overall positive or negative.
  """

  argument :text, :string do
    allow_nil? false
    description "The text for analysis"
  end

  run prompt(
    LangChain.ChatModels.ChatOpenAI.new!(%{model: "gpt-4o"}),
    # Allow the model to use tools
    tools: true,
    # Or restrict to specific tools
    # tools: [:list, :of, :tool, :names],
    # Optionally provide a custom prompt template
    # prompt: "Analyze the sentiment of the following text: <%= @input.arguments.text %>"
  )
end
```

### Dynamic LLM Configuration

For runtime configuration (like environment variables), use a function to define the LLM:

```elixir
action :analyze_sentiment, :atom do
  argument :text, :string, allow_nil?: false
  
  run prompt(
    fn _input, _context -> 
      LangChain.ChatModels.ChatOpenAI.new!(%{
        model: "gpt-4o",
        # this can also be configured in application config, see langchain docs for more.
        api_key: System.get_env("OPENAI_API_KEY"),
        endpoint: System.get_env("OPENAI_ENDPOINT")
      })
    end,
    tools: false
  )
end
```

The function receives:
1. `input` - The action input
2. `context` - The execution context

### Best Practices for Prompt-Backed Actions

- Write clear, detailed descriptions for the action and its arguments
- Use constraints when appropriate to restrict outputs
- Consider providing a custom prompt for more complex tasks
- Test thoroughly with different inputs to ensure reliable results

## Model Context Protocol (MCP) Server

### Development MCP Server

For development environments, add the dev MCP server to your Phoenix endpoint:

```elixir
if code_reloading? do
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket

  plug AshAi.Mcp.Dev,
    protocol_version_statement: "2024-11-05",
    otp_app: :your_app

  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader
end
```

### Production MCP Server

For production environments, set up authentication and add the MCP router:

```elixir
# Add api_key strategy to your auth pipeline
pipeline :mcp do
  plug AshAuthentication.Strategy.ApiKey.Plug,
    resource: YourApp.Accounts.User,
    required?: false  # Set to true if all tools require authentication
end

# In your router
scope "/mcp" do
  pipe_through :mcp

  forward "/", AshAi.Mcp.Router,
    tools: [
      # List your tools here
      :read_posts,
      :create_post,
      :analyze_sentiment
    ],
    protocol_version_statement: "2024-11-05",
    otp_app: :my_app
end
```

## Testing

When testing AI components:
- Mock embedding model responses for consistent test results
- Test vector search with known embeddings
- For prompt-backed actions, consider using deterministic test models
- Verify tool access and permissions work as expected

<-- ash_ai-end -->
<-- ash-start -->
## ash usage
# Rules for working with Ash

## Understanding Ash

Ash is an opinionated, composable framework for building applications in Elixir. It provides a declarative approach to modeling your domain with resources at the center. Read documentation  *before* attempting to use it's features. Do not assume that you have prior knowledge of the framework or its conventions.

## Code Structure & Organization

- Organize code around domains and resources
- Each resource should be focused and well-named
- Create domain-specific actions rather than generic CRUD operations
- Put business logic inside actions rather than in external modules
- Use resources to model your domain entities

## Code Interfaces

Use code interfaces on domains to define the contract for calling into Ash resources. See the [Code interface guide for more](https://hexdocs.pm/ash/code-interfaces.html).

Define code interfaces on the domain, like this:

```elixir
resource ResourceName do
  define :fun_name, action: :action_name
end
```

For more complex interfaces with custom transformations:

```elixir
define :custom_action do
  action :action_name
  args [:arg1, :arg2]

  custom_input :arg1, MyType do
    transform do
      to :target_field
      using &MyModule.transform_function/1
    end
  end
end
```

Prefer using the primary read action for "get" style code interfaces, and using `get_by` when the field you are looking up by is the primary key or has an `identity` on the resource.

```elixir
resource ResourceName do
  define :get_thing, action: :read, get_by: [:id]
end
```

**Avoid direct Ash calls in web modules** - Don't use `Ash.get!/2` and `Ash.load!/2` directly in LiveViews/Controllers, similar to avoiding `Repo.get/2` outside context modules:

```elixir
# BAD - in LiveView/Controller
group = MyApp.Resource |> Ash.get!(id) |> Ash.load!(rel: [:nested])

# GOOD - use code interface with get_by
resource DashboardGroup do
  define :get_by_id, action: :read, get_by: [:id]
end

# Then call:
MyApp.Domain.get_dashboard_group_by_id!(id, load: [rel: [:nested]])
```

**Code interface options** - Prefer passing options directly to code interface functions rather than building queries manually:

```elixir
# PREFERRED - Concise and idiomatic
posts = MyApp.Blog.list_posts!(
  filter: [status: :published],
  load: [author: :profile, comments: [:author]],
  sort: [published_at: :desc],
  limit: 10
)

# Complex scenarios use the query option
users = MyApp.Accounts.list_users!(
  query: [filter: [active: true], load: [:profile], sort: [created_at: :desc]]
)

# AVOID - Verbose manual query building
query = MyApp.Post |> Ash.Query.filter(...) |> Ash.Query.load(...)
posts = MyApp.Blog.read!(query)
```

Supported options: `load:`, `filter:`, `sort:`, `limit:`, `offset:`, `query:`, `page:`, `stream?:`

**Using Scopes in LiveViews** - When using `Ash.Scope`, the scope will typically be assigned to `scope` in LiveViews and used like so:

```elixir
# In your LiveView
MyApp.Blog.create_post!("new post", scope: socket.assigns.scope)
```

Inside action hooks and callbacks, use the provided `context` parameter as your scope instead:

```elixir
|> Ash.Changeset.before_transaction(fn changeset, context ->
  MyApp.ExternalService.reserve_inventory(changeset, scope: context)
  changeset
end)
```

### Authorization Functions

For each action defined in a code interface, Ash automatically generates corresponding authorization check functions:

- `can_action_name?(actor, params \\ %{}, opts \\ [])` - Returns `true`/`false` for authorization checks
- `can_action_name(actor, params \\ %{}, opts \\ [])` - Returns `{:ok, true/false}` or `{:error, reason}`

Example usage:
```elixir
# Check if user can create a post
if MyApp.Blog.can_create_post?(current_user) do
  # Show create button
end

# Check if user can update a specific post
if MyApp.Blog.can_update_post?(current_user, post) do
  # Show edit button
end

# Check if user can destroy a specific comment
if MyApp.Blog.can_destroy_comment?(current_user, comment) do
  # Show delete button
end
```

These functions are particularly useful for conditional rendering of UI elements based on user permissions.

## Actions

- Create specific, well-named actions rather than generic ones
- Put all business logic inside action definitions
- Use hooks like `Ash.Changeset.after_action/2`, `Ash.Changeset.before_action/2` to add additional logic
  inside the same transaction.
- Use hooks like `Ash.Changeset.after_transaction/2`, `Ash.Changeset.before_transaction/2` to add additional logic
  outside the transaction.
- Use action arguments for inputs that need validation
- Use preparations to modify queries before execution
- Use changes to modify changesets before execution
- Use validations to validate changesets before execution
- Prefer domain code interfaces to call actions instead of directly building queries/changesets and calling functions in the `Ash` module
- A resource could be *only generic actions*. This can be useful when you are using a resource only to model behavior.

## Querying Data

Use `Ash.Query` to build queries for reading data from your resources. The query module provides a declarative way to filter, sort, and load data.

**Important**: You must `require Ash.Query` if you want to use `Ash.Query.filter/2`, as it is a macro.

```elixir
defmodule MyApp.SomeModule do
  require Ash.Query

  def get_active_posts do
    MyApp.Post
    |> Ash.Query.filter(status == :active)
    |> MyApp.Blog.read!()
  end
end
```

Common query operations:

- **Filter**: `Ash.Query.filter(query, field == value)`
- **Sort**: `Ash.Query.sort(query, field: :asc)`
- **Load relationships**: `Ash.Query.load(query, [:author, :comments])`
- **Limit**: `Ash.Query.limit(query, 10)`
- **Offset**: `Ash.Query.offset(query, 20)`

## Error Handling

Functions to call actions, like `Ash.create` and code interfaces like `MyApp.Accounts.register_user` all return ok/error tuples. All have `!` variations, like `Ash.create!` and `MyApp.Accounts.register_user!`. Use the `!` variations when you want to "let it crash", like if looking something up that should definitely exist, or calling an action that should always succeed. Always prefer the raising `!` variation over something like `{:ok, user} = MyApp.Accounts.register_user(...)`.

All Ash code returns errors in the form of `{:error, error_class}`. Ash categorizes errors into four main classes:

1. **Forbidden** (`Ash.Error.Forbidden`) - Occurs when a user attempts an action they don't have permission to perform
2. **Invalid** (`Ash.Error.Invalid`) - Occurs when input data doesn't meet validation requirements
3. **Framework** (`Ash.Error.Framework`) - Occurs when there's an issue with how Ash is being used
4. **Unknown** (`Ash.Error.Unknown`) - Occurs for unexpected errors that don't fit the other categories

These error classes help you catch and handle errors at an appropriate level of granularity. An error class will always be the "worst" (highest in the above list) error class from above. Each error class can contain multiple underlying errors, accessible via the `errors` field on the exception.

### Using Validations

Validations ensure that data meets your business requirements before it gets processed by an action. Unlike changes, validations cannot modify the changeset - they can only validate it or add errors.

Common validation patterns:

```elixir
# Built-in validations with custom messages
validate compare(:age, greater_than_or_equal_to: 18) do
  message "You must be at least 18 years old"
end
validate match(:email, "@")
validate one_of(:status, [:active, :inactive, :pending])

# Conditional validations
validate present(:phone_number) do
  where present(:contact_method) and eq(:contact_method, "phone")
end

# Action-specific vs global validations
actions do
  create :sign_up do
    validate present([:email, :password])  # Only for this action
  end
end

validations do
  validate present([:title, :body]), on: [:create, :update]  # Multiple actions
end
```

- Create **custom validation modules** for complex validation logic:
  ```elixir
  defmodule MyApp.Validations.UniqueUsername do
    use Ash.Resource.Validation

    @impl true
    def init(opts), do: {:ok, opts}

    @impl true
    def validate(changeset, _opts, _context) do
      # Validation logic here
      # Return :ok or {:error, message}
    end
  end

  # Usage in resource:
  validate {MyApp.Validations.UniqueUsername, []}
  ```

- Make validations **atomic** when possible to ensure they work correctly with direct database operations by implementing the `atomic/3` callback in custom validation modules.

```elixir
defmodule MyApp.Validations.IsEven do
  # transform and validate opts

  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if is_atom(opts[:attribute]) do
      {:ok, opts}
    else
      {:error, "attribute must be an atom!"}
    end
  end

  @impl true
  # This is optional, but useful to have in addition to validation
  # so you get early feedback for validations that can otherwise
  # only run in the datalayer
  def validate(changeset, opts, _context) do
    value = Ash.Changeset.get_attribute(changeset, opts[:attribute])

    if is_nil(value) || (is_number(value) && rem(value, 2) == 0) do
      :ok
    else
      {:error, field: opts[:attribute], message: "must be an even number"}
    end
  end

  @impl true
  def atomic(changeset, opts, context) do
    {:atomic,
      # the list of attributes that are involved in the validation
      [opts[:attribute]],
      # the condition that should cause the error
      # here we refer to the new value or the current value
      expr(rem(^atomic_ref(opts[:attribute]), 2) != 0),
      # the error expression
      expr(
        error(^InvalidAttribute, %{
          field: ^opts[:attribute],
          # the value that caused the error
          value: ^atomic_ref(opts[:attribute]),
          # the message to display
          message: ^(context.message || "%{field} must be an even number"),
          vars: %{field: ^opts[:attribute]}
        })
      )
    }
  end
end
```

- **Avoid redundant validations** - Don't add validations that duplicate attribute constraints:
  ```elixir
  # WRONG - redundant validation
  attribute :name, :string do
    allow_nil? false
    constraints min_length: 1
  end

  validate present(:name) do  # Redundant! allow_nil? false already handles this
    message "Name is required"
  end

  validate attribute_does_not_equal(:name, "") do  # Redundant! min_length: 1 already handles this
    message "Name cannot be empty"
  end

  # CORRECT - let attribute constraints handle basic validation
  attribute :name, :string do
    allow_nil? false
    constraints min_length: 1
  end
  ```

### Using Changes

Changes allow you to modify the changeset before it gets processed by an action. Unlike validations, changes can manipulate attribute values, add attributes, or perform other data transformations.

Common change patterns:

```elixir
# Built-in changes with conditions
change set_attribute(:status, "pending")
change relate_actor(:creator) do
  where present(:actor)
end
change atomic_update(:counter, expr(^counter + 1))

# Action-specific vs global changes
actions do
  create :sign_up do
    change set_attribute(:joined_at, expr(now()))  # Only for this action
  end
end

changes do
  change set_attribute(:updated_at, expr(now())), on: :update  # Multiple actions
  change manage_relationship(:items, type: :append), on: [:create, :update]
end
```

- Create **custom change modules** for reusable transformation logic:
  ```elixir
  defmodule MyApp.Changes.SlugifyTitle do
    use Ash.Resource.Change

    def change(changeset, _opts, _context) do
      title = Ash.Changeset.get_attribute(changeset, :title)

      if title do
        slug = title |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
        Ash.Changeset.change_attribute(changeset, :slug, slug)
      else
        changeset
      end
    end
  end

  # Usage in resource:
  change {MyApp.Changes.SlugifyTitle, []}
  ```

- Create a **change module with lifecycle hooks** to handle complex multi-step operations:

```elixir
defmodule MyApp.Changes.ProcessOrder do
  use Ash.Resource.Change

  def change(changeset, _opts, context) do
    changeset
    |> Ash.Changeset.before_transaction(fn changeset ->
      # Runs before the transaction starts
      # Use for external API calls, logging, etc.
      MyApp.ExternalService.reserve_inventory(changeset, scope: context)
      changeset
    end)
    |> Ash.Changeset.before_action(fn changeset ->
      # Runs inside the transaction before the main action
      # Use for related database changes in the same transaction
      Ash.Changeset.change_attribute(changeset, :processed_at, DateTime.utc_now())
    end)
    |> Ash.Changeset.after_action(fn changeset, result ->
      # Runs inside the transaction after the main action, only on success
      # Use for related database changes that depend on the result
      MyApp.Inventory.update_stock_levels(result, scope: context)
      {changeset, result}
    end)
    |> Ash.Changeset.after_transaction(fn changeset,
      {:ok, result} ->
        # Runs after the transaction completes (success or failure)
        # Use for notifications, external systems, etc.
        MyApp.Mailer.send_order_confirmation(result, scope: context)
        {changeset, result}

      {:error, error} ->
        # Runs after the transaction completes (success or failure)
        # Use for notifications, external systems, etc.
        MyApp.Mailer.send_order_issue_notice(result, scope: context)
        {:error, error}
    end)
  end
end

# Usage in resource:
change {MyApp.Changes.ProcessOrder, []}
```

## Anonymous Functions

Prefer to put code in its own module and refer to that in changes, preparations, validations etc.

For example, prefer this:

```elixir
# in
defmodule MyApp.MyDomain.MyResource.Changes.SlugifyName do
  use Ash.Resource.Change

  def change(changeset, _, _) do
    Ash.Changeset.before_action(changeset, fn changeset, _ ->
      slug = MyApp.Slug.get()
      Ash.Changeset.force_change_attribute(changeset, :slug, slug)
    end)
  end
end

change MyApp.MyDomain.MyResource.Changes.SlugifyName
```

### Action Types

- **Read**: For retrieving records
- **Create**: For creating records
- **Update**: For changing records
- **Destroy**: For removing records
- **Generic**: For custom operations that don't fit the other types

## Relationships

Relationships describe connections between resources and are a core component of Ash. Define relationships in the `relationships` block of a resource.

### Best Practices for Relationships

- Be descriptive with relationship names (e.g., use `:authored_posts` instead of just `:posts`)
- Configure foreign key constraints in your data layer if they have them (see `references` in AshPostgres)
- Always choose the appropriate relationship type based on your domain model

#### Relationship Types

```elixir
relationships do
  # belongs_to - adds foreign key to source resource
  belongs_to :owner, MyApp.User do
    allow_nil? false
    attribute_type :integer  # defaults to :uuid
  end

  # has_one - foreign key on destination resource
  has_one :profile, MyApp.Profile

  # has_many - foreign key on destination resource, returns list
  has_many :posts, MyApp.Post do
    filter expr(published == true)
    sort published_at: :desc
  end

  # many_to_many - requires join resource
  many_to_many :tags, MyApp.Tag do
    through MyApp.PostTag
    source_attribute_on_join_resource :post_id
    destination_attribute_on_join_resource :tag_id
  end
end
```

The join resource must be defined separately:

```elixir
defmodule MyApp.PostTag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    # Add additional attributes if you need metadata on the relationship
    attribute :added_at, :utc_datetime_usec do
      default &DateTime.utc_now/0
    end
  end

  relationships do
    belongs_to :post, MyApp.Post, primary_key?: true, allow_nil?: false
    belongs_to :tag, MyApp.Tag, primary_key?: true, allow_nil?: false
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end
end
```

### Loading Relationships

```elixir
# Using code interface options (preferred)
post = MyDomain.get_post!(id, load: [:author, comments: [:author]])

# Complex loading with filters
posts = MyDomain.list_posts!(
  query: [load: [comments: [filter: [is_approved: true], limit: 5]]]
)

# Manual query building (for complex cases)
MyApp.Post
|> Ash.Query.load(comments: MyApp.Comment |> Ash.Query.filter(is_approved == true))
|> Ash.read!()

# Loading on existing records
Ash.load!(post, :author)
```

Prefer to use the `strict?` option when loading to only load necessary fields on related data.

```Elixir
MyApp.Post
|> Ash.Query.load([comments: [:title]], strict?: true)
```

### Managing Relationships

There are two primary ways to manage relationships in Ash:

#### 1. Using `change manage_relationship/2-3` in Actions
Use this when input comes from action arguments:

```elixir
actions do
  update :update do
    # Define argument for the related data
    argument :comments, {:array, :map} do
      allow_nil? false
    end

    argument :new_tags, {:array, :map}

    # Link argument to relationship management
    change manage_relationship(:comments, type: :append)

    # For different argument and relationship names
    change manage_relationship(:new_tags, :tags, type: :append)
  end
end
```

#### 2. Using `Ash.Changeset.manage_relationship/3-4` in Custom Changes
Use this when building values programmatically:

```elixir
defmodule MyApp.Changes.AssignTeamMembers do
  use Ash.Resource.Change

  def change(changeset, _opts, context) do
    members = determine_team_members(changeset, context.actor)

    Ash.Changeset.manage_relationship(
      changeset,
      :members,
      members,
      type: :append_and_remove
    )
  end
end
```

#### Quick Reference - Management Types
- `:append` - Add new related records, ignore existing
- `:append_and_remove` - Add new related records, remove missing
- `:remove` - Remove specified related records
- `:direct_control` - Full CRUD control (create/update/destroy)
- `:create` - Only create new records

#### Quick Reference - Common Options
- `on_lookup: :relate` - Look up and relate existing records
- `on_no_match: :create` - Create if no match found
- `on_match: :update` - Update existing matches
- `on_missing: :destroy` - Delete records not in input
- `value_is_key: :name` - Use field as key for simple values

For comprehensive documentation, see the [Managing Relationships](documentation/topics/resources/relationships.md#managing-relationships) section.

#### Examples

Creating a post with tags:
```elixir
MyDomain.create_post!(%{
  title: "New Post",
  body: "Content here...",
  tags: [%{name: "elixir"}, %{name: "ash"}]  # Creates new tags
})

# Updating a post to replace its tags
MyDomain.update_post!(post, %{
  tags: [tag1.id, tag2.id]  # Replaces tags with existing ones by ID
})
```

## Generating Code

Use `mix ash.gen.*` tasks as a basis for code generation when possible. Check the task docs with `mix help <task>`.
Be sure to use `--yes` to bypass confirmation prompts. Use `--yes --dry-run` to preview the changes.

## Data Layers

Data layers determine how resources are stored and retrieved. Examples of data layers:

- **Postgres**: For storing resources in PostgreSQL (via `AshPostgres`)
- **ETS**: For in-memory storage (`Ash.DataLayer.Ets`)
- **Mnesia**: For distributed storage (`Ash.DataLayer.Mnesia`)
- **Embedded**: For resources embedded in other resources (`data_layer: :embedded`) (typically JSON under the hood)
- **Ash.DataLayer.Simple**: For resources that aren't persisted at all. Leave off the data layer, as this is the default.

Specify a data layer when defining a resource:

```elixir
defmodule MyApp.Post do
  use Ash.Resource,
    domain: MyApp.Blog,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "posts"
    repo MyApp.Repo
  end

  # ... attributes, relationships, etc.
end
```

For embedded resources:

```elixir
defmodule MyApp.Address do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :street, :string
    attribute :city, :string
    attribute :state, :string
    attribute :zip, :string
  end
end
```

Each data layer has its own configuration options and capabilities. Refer to the rules & documentation of the specific data layer package for more details.

## Migrations and Schema Changes

After creating or modifying Ash code, run `mix ash.codegen <short_name_describing_changes>` to ensure any required additional changes are made (like migrations are generated). The name of the migration should be lower_snake_case. In a longer running dev session it's usually better to use `mix ash.codegen --dev` as you go and at the end run the final codegen with a sensible name describing all the changes made in the session.

## Authorization

- When performing administrative actions, you can bypass authorization with `authorize?: false`
- To run actions as a particular user, look that user up and pass it as the `actor` option
- Always set the actor on the query/changeset/input, not when calling the action
- Use policies to define authorization rules

```elixir
# Good
Post
|> Ash.Query.for_read(:read, %{}, actor: current_user)
|> Ash.read!()

# BAD, DO NOT DO THIS
Post
|> Ash.Query.for_read(:read, %{})
|> Ash.read!(actor: current_user)
```

### Policies

To use policies, add the `Ash.Policy.Authorizer` to your resource:

```elixir
defmodule MyApp.Post do
  use Ash.Resource,
    domain: MyApp.Blog,
    authorizers: [Ash.Policy.Authorizer]

  # Rest of resource definition...
end
```

### Policy Basics

Policies determine what actions on a resource are permitted for a given actor. Define policies in the `policies` block:

```elixir
policies do
  # A simple policy that applies to all read actions
  policy action_type(:read) do
    # Authorize if record is public
    authorize_if expr(public == true)

    # Authorize if actor is the owner
    authorize_if relates_to_actor_via(:owner)
  end

  # A policy for create actions
  policy action_type(:create) do
    # Only allow active users to create records
    forbid_unless actor_attribute_equals(:active, true)

    # Ensure the record being created relates to the actor
    authorize_if relating_to_actor(:owner)
  end
end
```

### Policy Evaluation Flow

Policies evaluate from top to bottom with the following logic:

1. All policies that apply to an action must pass for the action to be allowed
2. Within each policy, checks evaluate from top to bottom
3. The first check that produces a decision determines the policy result
4. If no check produces a decision, the policy defaults to forbidden

### IMPORTANT: Policy Check Logic

**the first check that yields a result determines the policy outcome**

```elixir
# WRONG - This is OR logic, not AND logic!
policy action_type(:update) do
  authorize_if actor_attribute_equals(:admin?, true)    # If this passes, policy passes
  authorize_if relates_to_actor_via(:owner)           # Only checked if first fails
end
```

To require BOTH conditions in that exmaple, you would use `forbid_unless` for the first condition:

```elixir
# CORRECT - This requires BOTH conditions
policy action_type(:update) do
  forbid_unless actor_attribute_equals(:admin?, true)  # Must be admin
  authorize_if relates_to_actor_via(:owner)           # AND must be owner
end
```

Alternative patterns for AND logic:
- Use multiple separate policies (each must pass independently)
- Use a single complex expression with `expr(condition1 and condition2)`
- Use `forbid_unless` for required conditions, then `authorize_if` for the final check

### Bypass Policies

Use bypass policies to allow certain actors to bypass other policy restrictions. This should be used almost exclusively for admin bypasses.

```elixir
policies do
  # Bypass policy for admins - if this passes, other policies don't need to pass
  bypass actor_attribute_equals(:admin, true) do
    authorize_if always()
  end

  # Regular policies follow...
  policy action_type(:read) do
    # ...
  end
end
```

### Field Policies

Field policies control access to specific fields (attributes, calculations, aggregates):

```elixir
field_policies do
  # Only supervisors can see the salary field
  field_policy :salary do
    authorize_if actor_attribute_equals(:role, :supervisor)
  end

  # Allow access to all other fields
  field_policy :* do
    authorize_if always()
  end
end
```

### Policy Checks

There are two main types of checks used in policies:

1. **Simple checks** - Return true/false answers (e.g., "is the actor an admin?")
2. **Filter checks** - Return filters to apply to data (e.g., "only show records owned by the actor")

You can use built-in checks or create custom ones:

```elixir
# Built-in checks
authorize_if actor_attribute_equals(:role, :admin)
authorize_if relates_to_actor_via(:owner)
authorize_if expr(public == true)

# Custom check module
authorize_if MyApp.Checks.ActorHasPermission
```

#### Custom Policy Checks

Create custom checks by implementing `Ash.Policy.SimpleCheck` or `Ash.Policy.FilterCheck`:

```elixir
# Simple check - returns true/false
defmodule MyApp.Checks.ActorHasRole do
  use Ash.Policy.SimpleCheck

  def match?(%{role: actor_role}, _context, opts) do
    actor_role == (opts[:role] || :admin)
  end
  def match?(_, _, _), do: false
end

# Filter check - returns query filter
defmodule MyApp.Checks.VisibleToUserLevel do
  use Ash.Policy.FilterCheck

  def filter(actor, _authorizer, _opts) do
    expr(visibility_level <= ^actor.user_level)
  end
end

# Usage
policy action_type(:read) do
  authorize_if {MyApp.Checks.ActorHasRole, role: :manager}
  authorize_if MyApp.Checks.VisibleToUserLevel
end
```

## Calculations

Calculations allow you to define derived values based on a resource's attributes or related data. Define calculations in the `calculations` block of a resource:

```elixir
calculations do
  # Simple expression calculation
  calculate :full_name, :string, expr(first_name <> " " <> last_name)

  # Expression with conditions
  calculate :status_label, :string, expr(
    cond do
      status == :active -> "Active"
      status == :pending -> "Pending Review"
      true -> "Inactive"
    end
  )

  # Using module calculations for more complex logic
  calculate :risk_score, :integer, {MyApp.Calculations.RiskScore, min: 0, max: 100}
end
```

### Expression Calculations

Expression calculations use Ash expressions and can be pushed down to the data layer when possible:

```elixir
calculations do
  # Simple string concatenation
  calculate :full_name, :string, expr(first_name <> " " <> last_name)

  # Math operations
  calculate :total_with_tax, :decimal, expr(amount * (1 + tax_rate))

  # Date manipulation
  calculate :days_since_created, :integer, expr(
    date_diff(^now(), inserted_at, :day)
  )
end
```

### Module Calculations

For complex calculations, create a module that implements `Ash.Resource.Calculation`:

```elixir
defmodule MyApp.Calculations.FullName do
  use Ash.Resource.Calculation

  # Validate and transform options
  @impl true
  def init(opts) do
    {:ok, Map.put_new(opts, :separator, " ")}
  end

  # Specify what data needs to be loaded
  @impl true
  def load(_query, _opts, _context) do
    [:first_name, :last_name]
  end

  # Implement the calculation logic
  @impl true
  def calculate(records, opts, _context) do
    Enum.map(records, fn record ->
      [record.first_name, record.last_name]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(opts.separator)
    end)
  end
end

# Usage in a resource
calculations do
  calculate :full_name, :string, {MyApp.Calculations.FullName, separator: ", "}
end
```

### Calculations with Arguments

You can define calculations that accept arguments:

```elixir
calculations do
  calculate :full_name, :string, expr(first_name <> ^arg(:separator) <> last_name) do
    argument :separator, :string do
      allow_nil? false
      default " "
      constraints [allow_empty?: true, trim?: false]
    end
  end
end
```

### Using Calculations

```elixir
# Using code interface options (preferred)
users = MyDomain.list_users!(load: [full_name: [separator: ", "]])

# Filtering and sorting
users = MyDomain.list_users!(
  query: [
    filter: [full_name: [separator: " ", value: "John Doe"]],
    sort: [full_name: {[separator: " "], :asc}]
  ]
)

# Manual query building (for complex cases)
User |> Ash.Query.load(full_name: [separator: ", "]) |> Ash.read!()

# Loading on existing records
Ash.load!(users, :full_name)
```

### Code Interface for Calculations

Define calculation functions on your domain for standalone use:

```elixir
# In your domain
resource User do
  define_calculation :full_name, args: [:first_name, :last_name, {:optional, :separator}]
end

# Then call it directly
MyDomain.full_name("John", "Doe", ", ")  # Returns "John, Doe"
```

## Aggregates

Aggregates allow you to retrieve summary information over groups of related data, like counts, sums, or averages. Define aggregates in the `aggregates` block of a resource:

```elixir
aggregates do
  # Count the number of published posts for a user
  count :published_post_count, :posts do
    filter expr(published == true)
  end

  # Sum the total amount of all orders
  sum :total_sales, :orders, :amount

  # Check if a user has any admin roles
  exists :is_admin, :roles do
    filter expr(name == "admin")
  end
end
```

### Aggregate Types

- **count**: Counts related items meeting criteria
- **sum**: Sums a field across related items
- **exists**: Returns boolean indicating if matching related items exist
- **first**: Gets the first related value matching criteria
- **list**: Lists the related values for a specific field
- **max**: Gets the maximum value of a field
- **min**: Gets the minimum value of a field
- **avg**: Gets the average value of a field

### Using Aggregates

```elixir
# Using code interface options (preferred)
users = MyDomain.list_users!(
  load: [:published_post_count, :total_sales],
  query: [
    filter: [published_post_count: [greater_than: 5]],
    sort: [published_post_count: :desc]
  ]
)

# Manual query building (for complex cases)
User |> Ash.Query.filter(published_post_count > 5) |> Ash.read!()

# Loading on existing records
Ash.load!(users, :published_post_count)
```

### Join Filters

For complex aggregates involving multiple relationships, use join filters:

```elixir
aggregates do
  sum :redeemed_deal_amount, [:redeems, :deal], :amount do
    # Filter on the aggregate as a whole
    filter expr(redeems.redeemed == true)

    # Apply filters to specific relationship steps
    join_filter :redeems, expr(redeemed == true)
    join_filter [:redeems, :deal], expr(active == parent(require_active))
  end
end
```

### Inline Aggregates

Use aggregates inline within expressions:

```elixir
calculate :grade_percentage, :decimal, expr(
  count(answers, query: [filter: expr(correct == true)]) * 100 /
  count(answers)
)
```

## Testing

When testing resources:
- Test your domain actions through the code interface
- Use test utilities in `Ash.Test`
- Test authorization policies work as expected using `Ash.can?`
- Use `authorize?: false` in tests where authorization is not the focus
- Write generators using `Ash.Generator`
- Prefer to use raising versions of functions whenever possible, as opposed to pattern matching

<-- ash-end -->
<-- usage-rules-end -->
