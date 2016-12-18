data "template_file" "bootstrap_powershell" {
    template = "${file("${path.module}/bootstrap_powershell.ps1.template")}"
    vars {
        domain = "${var.ad-domain}"
        netbios-name = "${var.ad-netbios-name}"
        safe-mode-password = "${var.ad-pwd}"
    }
}

data "template_file" "autologon_xml" {
    template ="${file("${path.module}/autologon.xml.template")}"
    vars {
        username = "${var.ad-user}"
        password = "${var.ad-pwd}"
    }
}

resource "azurerm_virtual_machine" "vm" {
    name = "${var.instance-name}"
    location = "${var.azure-region}"
    resource_group_name = "${azurerm_resource_group.core.name}"
    network_interface_ids = ["${azurerm_network_interface.win-interface.id}"]
    vm_size = "${var.instance-type}"
    delete_os_disk_on_termination = true

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer = "WindowsServer"
        sku = "2012-R2-Datacenter"
        version = "latest"
    }

    storage_os_disk {
        name = "${var.instance-name}"
        vhd_uri = "${azurerm_storage_account.sa.primary_blob_endpoint}${azurerm_storage_container.imgstore.id}/${var.instance-name}.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "${var.instance-name}"
        admin_username = "${var.ad-user}"
        admin_password = "${var.ad-pwd}"
        custom_data = "${base64encode(data.template_file.bootstrap_powershell.rendered)}"
    }

    os_profile_windows_config {
        additional_unattend_config {
            pass = "oobeSystem"
            component = "Microsoft-Windows-Shell-Setup"
            setting_name = "FirstLogonCommands"
            content = "${file("${path.module}/unattend.xml")}"
        }

        additional_unattend_config {
            pass = "oobeSystem"
            component = "Microsoft-Windows-Shell-Setup"
            setting_name = "AutoLogon"
            content = "${data.template_file.autologon_xml.rendered}"
        }
    }
}