{{- /*
    As we found Helm chart configuration of JupyterHub authentication was
    too complicated both to maintain and use in its badly maintained state,
    we sharply transitioned to a new system in 0.11.0.

    To help users transition, this file was developed. It converts the old
    auth configuration under "auth" to the new under "c". We detect if the
    old system is used and let the Helm chart's template rendering fail
    where we also provide a useful error message including the new config
    to use in its place.

    Implementation details:
    - Secret content must be censored
    - auth.state.cryptoKey needs a new home
*/}}

{{- define "jupyterhub.authDep.classKeyToLong.map" }}
google: oauthenticator.GoogleOAuthenticator
github: oauthenticator.github.GitHubOAuthenticator
cilogon: oauthenticator.CILogonOAuthenticator
gitlab: oauthenticator.gitlab.GitLabOAuthenticator
azuread: oauthenticator.azuread.AzureAdOAuthenticator
mediawiki: oauthenticator.mediawiki.MWOAuthenticator
globus: oauthenticator.globus.GlobusOAuthenticator
hmac: hmacauthenticator.HMACAuthenticator
dummy: dummyauthenticator.DummyAuthenticator
tmp: tmpauthenticator.TmpAuthenticator
lti: ltiauthenticator.LTIAuthenticator
ldap: ldapauthenticator.LDAPAuthenticator
{{- end }}

{{- /* Uses the map above, taking a keys, returning a value. */}}
{{- define "jupyterhub.authDep.classKeyToLong" -}}
    {{- $map := include "jupyterhub.authDep.classKeyToLong.map" . | fromYaml }}
    {{- index $map . }}
{{- end }}

{{- /* FIXME: we need to consider each of these and censor the secret stuff before rendering */}}
{{- define "jupyterhub.authDep.remapOldToNew.map" }}
scopes: OAuthenticator.scope
state.enabled: Authenticator.enable_auth_state
admin.access: JupyterHub.admin_access
admin.users: Authenticator.admin_users
whitelist.users: Authenticator.allowed_users
allowedUsers: Authenticator.allowed_users
google.clientId: GoogleOAuthenticator.client_id
google.clientSecret: GoogleOAuthenticator.client_secret
google.callbackUrl: GoogleOAuthenticator.oauth_callback_url
google.hostedDomain: GoogleOAuthenticator.hosted_domain
google.loginService: GoogleOAuthenticator.login_service
github.clientId: GitHubOAuthenticator.client_id
github.clientSecret: GitHubOAuthenticator.client_secret
github.callbackUrl: GitHubOAuthenticator.oauth_callback_url
github.orgWhitelist: GitHubOAuthenticator.allowed_organizations
github.allowedOrganizations: GitHubOAuthenticator.allowed_organizations
cilogon.clientId: CILogonOAuthenticator.client_id
cilogon.clientSecret: CILogonOAuthenticator.client_secret
cilogon.callbackUrl: CILogonOAuthenticator.oauth_callback_url
gitlab.clientId: GitLabOAuthenticator.client_id
gitlab.clientSecret: GitLabOAuthenticator.client_secret
gitlab.callbackUrl: GitLabOAuthenticator.oauth_callback_url
gitlab.gitlabGroupWhitelist: GitLabOAuthenticator.allowed_gitlab_groups
gitlab.allowedGitlabGroups: GitLabOAuthenticator.allowed_gitlab_groups
gitlab.gitlabProjectIdWhitelist: GitLabOAuthenticator.allowed_project_ids
gitlab.allowedProjectIds: GitLabOAuthenticator.allowed_project_ids
gitlab.gitlabUrl: GitLabOAuthenticator.gitlab_url
azuread.clientId: AzureAdOAuthenticator.client_id
azuread.clientSecret: AzureAdOAuthenticator.client_secret
azuread.callbackUrl: AzureAdOAuthenticator.oauth_callback_url
azuread.tenantId: AzureAdOAuthenticator.tenant_id
azuread.usernameClaim: AzureAdOAuthenticator.username_claim
mediawiki.clientId: MWOAuthenticator.client_id
mediawiki.clientSecret: MWOAuthenticator.client_secret
mediawiki.callbackUrl: MWOAuthenticator.oauth_callback_url
mediawiki.indexUrl: MWOAuthenticator.index_url
globus.clientId: GlobusOAuthenticator.client_id
globus.clientSecret: GlobusOAuthenticator.client_secret
globus.callbackUrl: GlobusOAuthenticator.oauth_callback_url
hmac.secretKey: HMACAuthenticator.secret_key
dummy.password: DummyAuthenticator.password
lti.consumers: LTIAuthenticator.consumers
ldap.server.address: LDAPAuthenticator.server_address
ldap.server.port: LDAPAuthenticator.server_port
ldap.server.ssl: LDAPAuthenticator.use_ssl
ldap.allowedGroups: LDAPAuthenticator.allowed_groups
ldap.dn.templates: LDAPAuthenticator.bind_dn_template
ldap.dn.lookup: LDAPAuthenticator.lookup_dn
ldap.dn.search.filter: LDAPAuthenticator.lookup_dn_search_filter
ldap.dn.search.user: LDAPAuthenticator.lookup_dn_search_user
ldap.dn.search.password: LDAPAuthenticator.lookup_dn_search_password
ldap.dn.user.dnAttribute: LDAPAuthenticator.lookup_dn_user_dn_attribute
ldap.dn.user.escape: LDAPAuthenticator.escape_userdn
ldap.dn.user.validRegex: LDAPAuthenticator.valid_username_regex
ldap.dn.user.searchBase: LDAPAuthenticator.user_search_base
ldap.dn.user.attribute: LDAPAuthenticator.user_attribute
ldap.dn.user.useLookupName: LDAPAuthenticator.use_lookup_dn_username
{{- end }}

{{- /* Uses the map above, taking a keys, returning a value. */}}
{{- define "jupyterhub.authDep.remapOldToNew.single" }}
    {{- $map := include "jupyterhub.authDep.remapOldToNew.map" . | fromYaml }}
    {{- index $map . }}
{{- end }}


{{- /*
    Recursively flattens a passed dict structure, outputs the result
    in a passed dict which is assumed to be empty.
*/}}
{{- define "jupyterhub.flattenDict" }}
    {{- $out := index . 0 }}
    {{- $dict := index . 1 }}

    {{- $label := "" }}
    {{- if eq (len .) 3 }}
        {{- $label = index . 2 }}
    {{- end }}

    {{- range $key, $val := $dict }}
        {{- $sublabel := list $label $key | join "." | trimPrefix "." }}
        {{- if kindOf $val | eq "map" }}
            {{- include "jupyterhub.flattenDict" (list $out $val $sublabel) }}
        {{- else }}
            {{- $_ := set $out $sublabel $val }}
        {{- end }}
    {{- end }}
{{- end }}

{{- /*
    Remaps Recursively flattens a passed dict structure, outputs the result
    in a passed dict which is assumed to be empty.
*/}}
{{- define "jupyterhub.authDep.remapOldToNew.mappable" -}}
    {{- range $key, $val := . }}
        {{- $_ := unset $ $key }}
        {{- $class_dot_new_key := include "jupyterhub.authDep.remapOldToNew.single" $key }}
        {{- if eq $class_dot_new_key "<no value>" }}
            {{- if not (hasKey $ "WarningUnrecognizedConfig") }}
                {{- $_ := set $ "WarningUnrecognizedConfig" dict }}
            {{- end }}
            {{- $_ := set (index $ "WarningUnrecognizedConfig") $key $val }}
        {{- else }}
            {{- $class := splitList "." $class_dot_new_key | first }}
            {{- $new_key := splitList "." $class_dot_new_key | last }}
            {{- if not (hasKey $ $class) }}
            {{- $_ := set $ $class dict }}
            {{- end }}
            {{- $_ := set (index $ $class) $new_key $val }}
        {{- end }}
    {{- end }}
{{- end }}

{{- define "jupyterhub.authDep.remapOldToNew" -}}
    {{- $c := dict }}
    {{- $result := dict "c" $c }}
    {{- /*
        Flattens the config in .Values.auth to a format of
        "keyX.keyY...": "value". Writes output to $c.
    */}}
    {{- include "jupyterhub.flattenDict" (list $c (omit .Values.auth "type" "custom")) }}

    {{- /*
        Transform the flattened config using a dictionary
        representing the old z2jh config, output the result
        in $c.
    */}}
    {{- include "jupyterhub.authDep.remapOldToNew.mappable" $c }}

    {{- $class_key := .Values.auth.type }}  {{- /* github */}}
    {{- $class_long := "" }}                {{- /* oauthenticator.github.GitHubOAuthenticator */}}
    {{- $class_short := "" }}               {{- /* GitHubOAuthenticator */}}

    {{- /* SET $class_long, $class_short */}}
    {{- if eq $class_key "custom" }}
        {{- $class_long = .Values.auth.custom.className }}
        {{- $class_short = $class_long | splitList "." | last }}
        {{- /* UPDATE c dict explicitly with auth.custom.config */}}
        {{- if .Values.auth.custom.config }}
            {{- /* FIXME: this could contain sensitive content! */}}
            {{- $_ := set $c $class_short .Values.auth.custom.config }}
        {{- end }}
    {{- else }}
        {{- $class_long = include "jupyterhub.authDep.classKeyToLong" $class_key }}
        {{- $class_short = $class_long | splitList "." | last }}
    {{- end }}

    {{- /* UPDATE c dict authenticator_class */}}
    {{- $_ := merge $c (dict "JupyterHub" (dict "authenticator_class" $class_long)) }}

    {{- /* RENDER result */}}
    {{- $result | toYaml }}
{{- end }}
