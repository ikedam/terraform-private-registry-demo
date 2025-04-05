package main

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	providerschema "github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/hashicorp/terraform-plugin-framework/resource"
)

// Provider implementation
type helloProvider struct{}

func (p *helloProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "example.com/example/hello"
}

func (p *helloProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = providerschema.Schema{}
}

func (p *helloProvider) Configure(_ context.Context, _ provider.ConfigureRequest, _ *provider.ConfigureResponse) {
}

func (p *helloProvider) Resources(_ context.Context) []func() resource.Resource {
	return nil
}

func (p *helloProvider) DataSources(_ context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		newHelloWorldDataSource,
	}
}

// DataSource implementation
type helloWorldDataSource struct{}

func newHelloWorldDataSource() datasource.DataSource {
	return &helloWorldDataSource{}
}

func (d *helloWorldDataSource) Metadata(_ context.Context, _ datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = "hello_world"
}

func (d *helloWorldDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"message": schema.StringAttribute{
				Computed:    true,
				Description: "A static message saying 'Hello, World!'",
			},
		},
	}
}

func (d *helloWorldDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	resp.Diagnostics.Append(resp.State.Set(ctx, map[string]any{
		"message": "Hello, World!",
	})...)
}

func NewProvider() provider.Provider {
	return &helloProvider{}
}

func main() {
	providerserver.Serve(context.Background(), NewProvider, providerserver.ServeOpts{
		Address: "example.com/example/hello",
	})
}
