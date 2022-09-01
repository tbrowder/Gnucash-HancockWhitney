[![Actions Status](https://github.com/tbrowder/Finance-Personal/actions/workflows/test.yml/badge.svg)](https://github.com/tbrowder/Finance-Personal/actions)

NAME
====

**Finance::Personal** - Provides Raku programs to use and manage financial transaction files

SYNOPSIS
========

```raku
use Finance::Personal;
```

DESCRIPTION
===========

**Finance::Personal** is a Raku module that provides programs to manage and transform your transactions and monthly statements from from banks and other financial institutions. In the process, its products should facilitate importing transactions into [GnuCash](https://gnucash.org), the free and open source double-entry accounting program.

Currently the module recognizes CSV products from the following institutions:

  * [Hancock-Whitney Bank](https://hancockwhitney.com) (HWB)

  * [Synovus Bank](https://synovus.com)

The information herein has been verified by the author from his regular use of it with his own HWB and Synovus personal accounts as a client, and he has no other relationship with those companies, their owners, or any of their subsidiaries.

Hancock-Whitney personal account products
-----------------------------------------

The following items are available for download for checking, money market (savings), and credit card (Visa) accounts:

  * Transactions in CSV format

  * Monthly statements in PDF format

The following products are also provided but will not be discussed further:

  * Transactions in OFX format

  * Transactions in formats for Money 2000, Quicken, and Quick Books

Product details
===============

Transactions in CSV format
--------------------------

The CSV transaction files are downloaded as needed by the client by specifying either a time period or the last 30 days. The downloaded filename has no apparent relation to anything and may result in a duplicated name with a ' (n)' inserted as is normal on many OSs.

This module has a program ?? that will process such a file and assemble transactions into separate files by month and named accordingly.

### CSV file header

The author's CSV file headers are shown here:

The client should download on a regular basis to ensure no tranactions are missed as HWB only provides data for the last 16 months. Older ones may be available for a fee.

Monthly statements in PDF format
--------------------------------

HWB monthly statements are named in a format like this: 'February 23, 2022.pdf'. Consequently, a directory listing is not in date order. Program ? can be used to rename them into ISO names so they sort properly in date order.

The client should download on a regular basis to ensure no tranactions are missed as HWB only provides data for the last 24 months. Older ones may be available for a fee.

TODO
----

  * Complete and document Synovus Bank transaction handling

  * Add other file format handling (OFX, json)

Program details
===============

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

