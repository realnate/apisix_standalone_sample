# Standalone APISIX Scripts

These PowerShells scripts configure and deploy [APISIX](https://apisix.apache.org/) in [Standalone mode](https://apisix.apache.org/docs/apisix/deployment-modes/#standalone). Standalone mode is an easy and a highly secure way to deploy and configure APISIX. A typical APISIX installation has multiple components including control plane, data plane, and ETCD. Communication occurs between these such as the control plane directing behavior in the data plane and etcd providing configuration values. Standalone mode reduces the deployment to only the data plane with its data being provided by a static yaml configuration files.

In this deployment model, all configuration for APISIX objects such as routes, upstreams, and plugins are done in the apisix.yaml file. Changes to these yaml configuration files will automatically trigger a reload of APISIX to apply the changes.

These scripts are intended to be used via automated CI/CD pipelines with the configuration being stored in source control.


## Dependencies

- **Kubectl** - fully configured to communicate with the intended cluster and with the proper context set.
- **Helm**

## up.ps1

The "up" script deploys APISIX in standalone mode along with its supporting objects.

Deploy using the "up" script. A minimal example (PowerShell):
```
.\up.ps1 -namespace apisix
```

This sample uses multiple parameters that either need to be supplied with a dictionary or via environment variables in the environment where the "up" script is executed. Parameters are described further below.
```
.\up.ps1 -namespace apisix -substitutions @{ `
  "docker_password"="my-secret-docker-password-value"; `
  "openid_connect_secret"="my-openid-connect-secret-value"; `
  "openid_connect_session_secret"="my-openid-connect-session-secret-value"; `
}
```

### Parameters

  - **-namespace**: the namespace where the apisix resources will be installed.Namespace will also be used as a prefix for the objects that exists outside of namespaces such as ClusterRoles and ClusterRoleBindings.

    **This is required.**

    Example: ```-namespace my_namespace``` will cause the objects to be created in a namespace named 'my_namespace'

  - **-reloaderHelmReleaseName**: the name for the Helm release of [stakaterReloader](https://github.com/stakater/Reloader).

    **This is optional**, the default value is 'reloader'.

    Example: ```-reloaderHelmReleaseName reloader``` will result in the helm release being named ```reloader```.

  - **-substitutions**: a dictionary of parameters to replace within YAML template files. 

    **This is optional.**   
    Example: ```-substitutions @{'param1'='value1', 'param2'='value2'}``` will cause instances of ```$(param1)``` to be replaced with ```value1``` and ```(param2)``` to be replaced with ```value2```

## down.ps1

The "down" script removes the objects created by the "up" script.

Remove using the "down" script, for example (PowerShell): 
```
.\down.ps1 -namespace apisix
```

Parameters may not be required in the "down" script as they are in the "up" script. They are generally required for anything related to object names. The easiest approach is to just supply the same as the "up" script even if not required to avoid any issues.

### Parameters

  - **-namespace**: the namespace where the apisix resources are installed.Namespace will also be used as a prefix for the objects that exists outside ofnamespaces such as ClusterRoles and ClusterRoleBindings.

    **This is required.**

    Example: ```-namespace my_namespace``` will cause the objects to be deleted from a namespace named 'my_namespace'

  - **-reloaderHelmReleaseName**: the name for the Helm release of [stakaterReloader](https://github.com/stakater/Reloader).

    **This is optional**, the default value is 'reloader'.

    Example: ```-reloaderHelmReleaseName reloader``` will result in the helm release named ```reloader``` being deleted.

  - **-substitutions**: a dictionary of parameters to replace within YAML templatefiles. 

    **This is optional.**   
    Example: ```-substitutions @{'param1'='value1', 'param2'='value2'}``` willcause instances of ```$(param1)``` to be replaced with ```value1``` and ```(param2)``` to be replaced with ```value2```

  - **-removeEntireNamespace**: When true, after deleting individual objects, the entire namespace specified will also be deleted recursively.


## Parameterization
Before running up.ps1 and down.ps1 environment variables can be used in the 3 yaml files (apisix-deploy.yaml, apisix.yaml, and config.yaml) using the syntax $(variable_name).

A dictionary can also be passed to the scripts, e.g. (PowerShell)

```
.\up.ps1 -namespace apisix -reloaderHelmReleaseName reloader `
  -substitutions @{'my-parameter-1'='my-value-1'; 'my-parameter-2'='my-value-2'}

.\down.ps1 -namespace apisix `
  -reloaderHelmReleaseName reloader `
  -removeEntireNamespace $false `
  -substitutions @{'my-parameter-1'='my-value-1'; 'my-parameter-2'='my-value-2'}
```

In this example, within YAML files ```$(my-parameter-1)``` will be replaced with ```my-value-1``` and ```$(my-parameter-2)``` will be replaced with ```my-value-2```.

You cannot supply the parameter 'namespace' via the substitutions argument, it will be replaced with the namespace parameter at execution.

## Customization

Modify ```apisix.yaml``` with APISIX routes, upstreams, plugins, etc.

Any changes to the configmaps at runtime will result in Apisix restarting using the new values.

See https://apisix.apache.org/docs/apisix/next/deployment-modes/#standalone for examples.

## Sample execution
```.\up.ps1 -namespace apisix -substitutions @{'docker_password'='...'; 'openid-connect-session-secret'='...'}```

## License

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
