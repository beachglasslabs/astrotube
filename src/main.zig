const std = @import("std");
const zap = @import("zap");
const UserEndpoint = @import("user_endpoint.zig");
const SessionEndpoint = @import("session_endpoint.zig");
const MovieEndpoint = @import("movie_endpoint.zig");
const Router = @import("router.zig");
const EndpointRouter = @import("endpoint_router.zig");
const Auth = @import("authenticator.zig");
const User = @import("users.zig").User;
const Session = @import("sessions.zig").Session;
const Template = @import("template.zig");

// just a way to share our allocator via callback
const SharedAllocator = struct {
    // static
    var allocator: std.mem.Allocator = undefined;

    const Self = @This();

    // just a convenience function
    pub fn init(a: std.mem.Allocator) void {
        allocator = a;
    }

    // static function we can pass to the listener later
    pub fn getAllocator() std.mem.Allocator {
        return allocator;
    }
};

// create a combined context struct
// const Context = zap.Middleware.MixContexts(.{
//     .{ .name = "?user", .type = User },
//     .{ .name = "?session", .type = std.StringHashMap(void) },
// });
const Context = struct {
    user: ?User = null,
    session: ?std.StringHashMap(void) = null,
};

// we create a Handler type based on our Context
const Handler = zap.Middleware.Handler(Context);

fn index(renderer: Template, r: zap.SimpleRequest, context: *Context) bool {
    if (context.user) |user| {
        std.debug.print("index: user is {s}\n", .{user.name});
        renderer.render(r, "web/templates/index.html", .{ .name = user.name, .avatar = user.avatar }) catch return true;
    } else {
        std.debug.print("index: user is null\n", .{});
        redirect(r);
    }
    return true;
}

fn redirect(r: zap.SimpleRequest) void {
    r.redirectTo("/sessions", zap.StatusCode.see_other) catch return;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};

    {
        var allocator = gpa.allocator();
        SharedAllocator.init(allocator);

        // read config
        const file = try std.fs.cwd().openFile("env.oauth.json", .{});
        defer file.close();

        const size = (try file.stat()).size;

        const source = try file.reader().readAllAlloc(allocator, size);
        defer allocator.free(source);

        const OauthConfig = struct { name: []const u8, version: []const u8, providers: struct {
            google: struct {
                id: []const u8,
                secret: []const u8,
            },
            github: struct {
                id: []const u8,
                secret: []const u8,
            },
        } };
        var config = try std.json.parseFromSlice(OauthConfig, allocator, source, .{});
        defer config.deinit();

        // setup routes
        var router = try Router.Router(Context).init(allocator);
        defer router.deinit();

        try router.get("/", index);

        var htmlHandler = zap.Middleware.EndpointHandler(Handler, Context).init(
            router.getEndpoint(),
            null,
            true,
        );

        var movie_endpoint = try MovieEndpoint.init(allocator, "/movies", "web/movies.json");
        defer movie_endpoint.deinit();

        var session_endpoint = SessionEndpoint.init(allocator, "/sessions");
        defer session_endpoint.deinit();

        const UserManager = UserEndpoint.UserEndpoint(MovieEndpoint, Context);
        var user_endpoint = UserManager.init(allocator, "/users", &movie_endpoint);
        defer user_endpoint.deinit();

        // create authenticator
        const Authenticator = Auth.Authenticator(UserEndpoint.UserEndpoint(MovieEndpoint, Context), SessionEndpoint, Context);
        const auth_settings = Auth.AuthSettings{
            .name_param = "name",
            .subject_param = "email",
            .password_param = "password",
            .whitelist = &[_][]const u8{"/sessions"},
            .success_url = "/users",
            .failure_url = "/sessions",
            .signin_callback = "/sessions",
            .signup_callback = "/users",
            .cookie_name = "token",
            .cookie_maxage = 1337,
            .redirect_code = zap.StatusCode.see_other,
        };
        const oauth_settings = Auth.OauthSettings{
            .google_redirect = "/oauth2/google/redirect",
            .github_redirect = "/oauth2/github/redirect",
            .google_callback = "/oauth2/google/callback",
            .github_callback = "/oauth2/github/callback",
            .google_client_id = config.value.providers.google.id,
            .google_client_secret = config.value.providers.google.secret,
            .github_client_id = config.value.providers.github.id,
            .github_client_secret = config.value.providers.github.secret,
        };

        var authenticator = try Authenticator.init(allocator, &user_endpoint, &session_endpoint, auth_settings, oauth_settings);
        defer authenticator.deinit();

        // create authenticating endpoint
        const MainRouter = EndpointRouter.EndpointRouter(Authenticator);
        var dispatcher = MainRouter.init(allocator, &authenticator);
        defer dispatcher.deinit();

        // add endpoints
        try dispatcher.addEndpoint(user_endpoint.getEndpoint());
        try dispatcher.addEndpoint(session_endpoint.getEndpoint());
        try dispatcher.addEndpoint(movie_endpoint.getEndpoint());

        var superHandler = zap.Middleware.EndpointHandler(Handler, Context).init(
            dispatcher.getEndpoint(),
            htmlHandler.getHandler(),
            true,
        );

        // setup listener
        // we create a listener with our combined context
        // and pass it the initial handler: the user handler
        var listener = try zap.Middleware.Listener(Context).init(
            .{
                .on_request = null,
                .port = 3000,
                .public_folder = "public",
                .log = true,
                .max_clients = 100000,
            },
            superHandler.getHandler(),
            SharedAllocator.getAllocator,
        );
        zap.enableDebugLog();
        //defer listener.deinit();

        // listen
        listener.listen() catch |err| {
            std.debug.print("\nLISTENER ERROR: {}\n", .{err});
            return;
        };

        std.debug.print("Listening on 0.0.0.0:3000\n", .{});

        // start worker threads
        zap.start(.{
            .threads = 5,
            // IMPORTANT! It is crucial to only have a single worker for this example to work!
            // Multiple workers would have multiple copies of the users hashmap.
            //
            // Since zap is quite fast, you can do A LOT with a single worker.
            // Try it with `zig build -Drelease-fast`
            .workers = 1,
        });
    }

    // all defers should have run by now
    std.debug.print("\n\nSTOPPED!\n\n", .{});
    // we'll arrive here after zap.stop()
    const leaked = gpa.detectLeaks();
    std.debug.print("Leaks detected: {}\n", .{leaked});
}
