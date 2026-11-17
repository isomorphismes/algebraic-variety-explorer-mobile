#ifndef SURFER_ACTIVITY_JNI_OWNER_H
#define SURFER_ACTIVITY_JNI_OWNER_H

/* Only the installed application's compiler-selected Activity changes owner.
 * Source/ART qualification fixtures retain the backend's default owner. */
#ifdef SURFER_APPLICATION_ACTIVITY_OWNER
#if SURFER_APPLICATION_ACTIVITY_OWNER != 1
#error "SURFER_APPLICATION_ACTIVITY_OWNER must be exactly 1 when selected"
#endif
#define SURFER_ACTIVITY_JNI(method) Java_org_algebraicvarietyexplorer_AVEActivity_ ## method
#else
#define SURFER_ACTIVITY_JNI(method) Java_Idric_Generated_ ## method
#endif

#endif
