#!perl
#use strict;


my @object_types = ( 'Asset', 
                     'Attribute', 
                     'Catalog', 
                     'CatalogItem', 
                     'CatalogItemPrice', 
                     'CatalogItemPrices', 
                     'CatalogItemRatings', 
                     'CatalogItemRecommendations',
                     'CatalogItemUpgrades',
                     'Category',
                     'Device',
                     'DownloadStatus',
                     'ErrorResult',
                     'Folder',
                     'ItemDataRequest',
                     'ItemsRequest',
                     'ManagedApp',
                     'Promotions',
                     'PromotionsRequest',
                     'RecommendationsRequest',
                     'SearchResults',
                     'SearchResultsRequest'
                   );
                   
                   
foreach my $object_type (@object_types)
{
   my $struct_typedef = lc $object_type.'_s';
   my $struct_type    = lc $object_type.'_t';
   my $interface      = 'I'.$object_type;
   my $classid_def    = 'AEEIID_'.$interface;
   my $new_func       = lcfirst $object_type.'_New';

my $cfile=<<EOCFILE;
/* $object_type.c */

#include "AEEShell.h"
#include "AEEStdLib.h"

#include "$object_type.h"
#include "Utility.h"

typedef struct $struct_typedef
{
   const AEEVTBL($interface) * pvt; 
   uint32       nRefs;
   IShell      *pIShell;
   IModule     *pIModule;
   ObjectPool  *pObjectPool;
}$struct_type;

#define ME_FROM_CLASS $struct_type *pMe = ($struct_type *)p

/* Function Prototypes */
static uint32 $object_type\_AddRef($interface *po);
static uint32 $object_type\_Release($interface *po);
static uint32 $object_type\_QueryInterface($interface *po, AEECLSID classID, void** ppo);

/* Interface functions */

// TODO: implement interface functions here

/* object creation */
int $new_func(IShell *pIShell, IModule* pIModule, ObjectPool *pObjPool, IModule ** ppMod)
{
   $struct_type         *pMe   = NULL;
   int               nSize = sizeof($struct_type);
   AEEVTBL($interface) *modFuncs;

   if(!ppMod || !pIShell || !pIModule) {
      return (EFAILED);
   }
   *ppMod = NULL;
   
   // Allocate memory for size of class and function table
   if(NULL == (pMe = ($struct_type *)MALLOC(nSize + sizeof($interface\Vtbl)))) {
      return (ENOMEMORY);
   }

   //Assign modFuncs ptr to memory allocated for class and advance nSize bytes
   modFuncs = ($interface\Vtbl *)((byte *)pMe + nSize);
   modFuncs->AddRef              = $object_type\_AddRef;
   modFuncs->QueryInterface      = $object_type\_QueryInterface;
   modFuncs->Release             = $object_type\_Release;
   // TODO: hook up vtable to implementations
   INIT_VTBL(pMe, IModule, *modFuncs); 

   // Initialize the internal member variables:
   pMe->pObjectPool = pObjPool;
   pMe->nRefs       = 1;
   pMe->pIShell     = pIShell;
   pMe->pIModule    = pIModule; 
   ISHELL_AddRef(pIShell); 
   // DO NOT ADD REF THE MODULE!!! IMODULE_AddRef(pIModule);
   *ppMod           = (IModule*)pMe; 

   return AEE_SUCCESS;
}

/* standard BREW interface funcs */

static uint32 $object_type\_AddRef($interface * po)
{ 
   return (++(($struct_type *)po)->nRefs);
}

static uint32 $object_type\_Release($interface *po) 
{
   $struct_type *pMe = ($struct_type *)po;
   if(--pMe->nRefs != 0) {
      return (pMe->nRefs);
   }
   ISHELL_Release(pMe->pIShell);
   // NO ADD REF, SO NO RELEASE!!! IMODULE_Release(pMe->pIModule);
   FREE_VTBL(pMe, IModule);
   FREE(pMe);
   return 0; 
}

static uint32 $object_type\_QueryInterface($interface *po, AEECLSID classID, void **ppo)
{
   switch (classID) {
      case AEECLSID_QUERYINTERFACE:
      case $classid_def:
      case AEECLSID_BASE:
         *ppo = po;
         $object_type\_AddRef(po);
         return SUCCESS; 
      default:
         *ppo = NULL;
         return (ECLASSNOTSUPPORT);
   }
}
EOCFILE

my $hfile=<<EOHFILE;

#ifndef _$object_type\_h_
#define _$object_type\_h_

#include "AEE$interface.h"
#include "ObjectPool.h"

int $new_func(IShell *pIShell, IModule *pIModule, ObjectPool *pObjPool, IModule **ppMod);

#endif
EOHFILE

print "creating $object_type.h/c\n";

open HFILE, ">$object_type.h" or die "Failed to open hfile.";
print HFILE $hfile;
close HFILE;

open CFILE, ">$object_type.c" or die "Failed to open cfile.";
print CFILE $cfile;
close CFILE;
}